// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler;

import 'dart:async';
import 'dart:collection' show SplayTreeMap;
import 'dart:json' as json;
import 'package:analyzer_experimental/src/generated/ast.dart' show Directive, UriBasedDirective;
import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart' show InfoVisitor, StyleSheet, treeToDebugString;
import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';

import 'analyzer.dart';
import 'code_printer.dart';
import 'codegen.dart' as codegen;
import 'dart_parser.dart';
import 'emitters.dart';
import 'file_system.dart';
import 'file_system/path.dart';
import 'files.dart';
import 'html_cleaner.dart';
import 'html_css_fixup.dart';
import 'info.dart';
import 'messages.dart';
import 'observable_transform.dart' show transformObservables;
import 'options.dart';
import 'refactor.dart';
import 'utils.dart';

/**
 * Parses an HTML file [contents] and returns a DOM-like tree.
 * Note that [contents] will be a [String] if coming from a browser-based
 * [FileSystem], or it will be a [List<int>] if running on the command line.
 *
 * Adds emitted error/warning to [messages], if [messages] is supplied.
 */
Document parseHtml(contents, Path sourcePath, Messages messages) {
  var parser = new HtmlParser(contents, generateSpans: true,
      sourceUrl: sourcePath.toString());
  var document = parser.parse();

  // Note: errors aren't fatal in HTML (unless strict mode is on).
  // So just print them as warnings.
  for (var e in parser.errors) {
    messages.warning(e.message, e.span, file: sourcePath);
  }
  return document;
}

/** Compiles an application written with Dart web components. */
class Compiler {
  final FileSystem fileSystem;
  final CompilerOptions options;
  final List<SourceFile> files = <SourceFile>[];
  final List<OutputFile> output = <OutputFile>[];

  Path _mainPath;
  PathInfo _pathInfo;
  Messages _messages;

  FutureGroup _tasks;
  Set _processed;

  bool _useObservers = false;

  /** Information about source [files] given their href. */
  final Map<Path, FileInfo> info = new SplayTreeMap<Path, FileInfo>();
  final _edits = new Map<DartCodeInfo, TextEditTransaction>();

 /**
  * Creates a compiler with [options] using [fileSystem].
  *
  * Adds emitted error/warning messages to [messages], if [messages] is
  * supplied.
  */
  Compiler(this.fileSystem, this.options, this._messages, {String currentDir}) {
    _mainPath = new Path(options.inputFile);
    var mainDir = _mainPath.directoryPath;
    var basePath =
        options.baseDir != null ? new Path(options.baseDir) : mainDir;
    var outputPath =
        options.outputDir != null ? new Path(options.outputDir) : mainDir;
    var packageRoot = options.packageRoot != null
        ? new Path(options.packageRoot)
        : _mainPath.directoryPath.join(new Path('packages'));

    // Normalize paths - all should be relative or absolute paths.
    bool anyAbsolute = _mainPath.isAbsolute || basePath.isAbsolute ||
        outputPath.isAbsolute || packageRoot.isAbsolute;
    bool allAbsolute = _mainPath.isAbsolute && basePath.isAbsolute &&
        outputPath.isAbsolute || packageRoot.isAbsolute;
    if (anyAbsolute && !allAbsolute) {
      if (currentDir == null)  {
        _messages.error('internal error: could not normalize paths. Please '
            'make the input, base, and output paths all absolute or relative, '
            'or specify "currentDir" to the Compiler constructor', null);
        return;
      }
      var currentPath = new Path(currentDir);
      if (!_mainPath.isAbsolute) _mainPath = currentPath.join(_mainPath);
      if (!basePath.isAbsolute) basePath = currentPath.join(basePath);
      if (!outputPath.isAbsolute) outputPath = currentPath.join(outputPath);
      if (!packageRoot.isAbsolute) {
        packageRoot = currentPath.join(packageRoot);
      }
    }
    _pathInfo = new PathInfo(basePath, outputPath, packageRoot,
        options.forceMangle);
  }

  /** Compile the application starting from the given [mainFile]. */
  Future run() {
    if (_mainPath.filename.endsWith('.dart')) {
      _messages.error("Please provide an HTML file as your entry point.",
          null, file: _mainPath);
      return new Future.immediate(null);
    }
    return _parseAndDiscover(_mainPath).then((_) {
      _analyze();
      _transformDart();
      _emit();
    });
  }

  /**
   * Asynchronously parse [inputFile] and transitively discover web components
   * to load and parse. Returns a future that completes when all files are
   * processed.
   */
  Future _parseAndDiscover(Path inputFile) {
    _tasks = new FutureGroup();
    _processed = new Set();
    _processed.add(inputFile);
    _tasks.add(_parseHtmlFile(inputFile).then(_processHtmlFile));
    return _tasks.future;
  }

  bool _shouldProcessFile(SourceFile file) =>
      file != null && _pathInfo.checkInputPath(file.path, _messages);

  void _processHtmlFile(SourceFile file) {
    if (!_shouldProcessFile(file)) return;

    bool isEntryPoint = _processed.length == 1;

    files.add(file);

    var fileInfo = _time('Analyzed definitions', file.path,
        () => analyzeDefinitions(file, _pathInfo.packageRoot, _messages,
            isEntryPoint: isEntryPoint));
    info[file.path] = fileInfo;

    _processImports(fileInfo);

    // Load component files referenced by [file].
    for (var href in fileInfo.componentLinks) {
      if (!_processed.contains(href)) {
        _processed.add(href);
        _tasks.add(_parseHtmlFile(href).then(_processHtmlFile));
      }
    }

    // Load stylesheet files referenced by [file].
    for (var href in fileInfo.styleSheetHref) {
      if (!_processed.contains(href)) {
        _processed.add(href);
        _tasks.add(_parseStyleSheetFile(href).then(_processStyleSheetFile));
      }
    }

    // Load .dart files being referenced in the page.
    var src = fileInfo.externalFile;
    if (src != null && !_processed.contains(src)) {
      _processed.add(src);
      _tasks.add(_parseDartFile(src).then(_processDartFile));
    }

    // Load .dart files being referenced in components.
    for (var component in fileInfo.declaredComponents) {
      var src = component.externalFile;
      if (src != null && !_processed.contains(src)) {
        _processed.add(src);
        _tasks.add(_parseDartFile(src).then(_processDartFile));
      } else if (component.userCode != null) {
        _processImports(component);
      }
    }
  }

  /** Asynchronously parse [path] as an .html file. */
  Future<SourceFile> _parseHtmlFile(Path path) {
    return fileSystem.readTextOrBytes(path).then((source) {
          var file = new SourceFile(path);
          file.document = _time('Parsed', path,
              () => parseHtml(source, path, _messages));
          return file;
        })
        .catchError((e) => _readError(e, path));
  }

  /** Parse [filename] and treat it as a .dart file. */
  Future<SourceFile> _parseDartFile(Path path) {
    return fileSystem.readText(path)
        .then((code) => new SourceFile(path, type: SourceFile.DART)
            ..code = code)
        .catchError((e) => _readError(e, path));
  }

  SourceFile _readError(error, Path path) {
    _messages.error('exception while reading file, original message:\n $error',
        null, file: path);

    return null;
  }

  void _processDartFile(SourceFile dartFile) {
    if (!_shouldProcessFile(dartFile)) return;

    files.add(dartFile);

    var fileInfo = new FileInfo(dartFile.path);
    info[dartFile.path] = fileInfo;
    fileInfo.inlinedCode =
        parseDartCode(fileInfo.path, dartFile.code, _messages);

    _processImports(fileInfo);
  }

  void _processImports(LibraryInfo library) {
    if (library.userCode == null) return;

    for (var directive in library.userCode.directives) {
      var src = _getDirectivePath(library, directive);
      if (src == null) {
        var uri = directive.uri.value;
        if (uri.startsWith('package:web_ui/observe')) {
          _useObservers = true;
        }
      } else if (!_processed.contains(src)) {
        _processed.add(src);
        _tasks.add(_parseDartFile(src).then(_processDartFile));
      }
    }
  }

  /** Parse [filename] and treat it as a .dart file. */
  Future<SourceFile> _parseStyleSheetFile(Path path) {
    return fileSystem.readText(path)
        .then((code) =>
            new SourceFile(path, type: SourceFile.STYLESHEET)..code = code)
        .catchError((e) => _readError(e, path));
  }

  void _processStyleSheetFile(SourceFile cssFile) {
    if (!_shouldProcessFile(cssFile)) return;

    files.add(cssFile);

    var fileInfo = new FileInfo(cssFile.path);
    info[cssFile.path] = fileInfo;

    var uriVisitor = new UriVisitor(_pathInfo, _mainPath, fileInfo.path,
        options.rewriteUrls);
    var styleSheet = _parseCss(cssFile.path.toString(),
        cssFile.code, uriVisitor, options);
    if (styleSheet != null) {
      fileInfo.styleSheets.add(styleSheet);
    }
  }

  Path _getDirectivePath(LibraryInfo libInfo, Directive directive) {
    var uriDirective = (directive as UriBasedDirective).uri;
    var uri = uriDirective.value;
    if (uri.startsWith('dart:')) return null;

    if (uri.startsWith('package:')) {
      // Don't process our own package -- we'll implement @observable manually.
      if (uri.startsWith('package:web_ui/')) return null;

      return _pathInfo.packageRoot.join(new Path(uri.substring(8)));
    } else {
      return libInfo.inputPath.directoryPath.join(new Path(uri));
    }
  }

  /**
   * Transform Dart source code.
   * Currently, the only transformation is [transformObservables].
   * Calls _emitModifiedDartFiles to write the transformed files.
   */
  void _transformDart() {
    var libraries = _findAllDartLibraries();

    var transformed = [];
    for (var lib in libraries) {
      var transaction = transformObservables(lib.userCode);
      if (transaction != null) {
        _edits[lib.userCode] = transaction;
        if (transaction.hasEdits) {
          _useObservers = true;
          transformed.add(lib);
        } else if (lib.htmlFile != null) {
          // All web components will be transformed too. Track that.
          transformed.add(lib);
        }
      }
    }

    _findModifiedDartFiles(libraries, transformed);

    libraries.forEach(_fixImports);

    _emitModifiedDartFiles(libraries);
  }

  /**
   * Finds all Dart code libraries.
   * Each library will have [LibraryInfo.inlinedCode] that is non-null.
   * Also each inlinedCode will be unique.
   */
  List<LibraryInfo> _findAllDartLibraries() {
    var libs = <LibraryInfo>[];
    void _addLibrary(LibraryInfo lib) {
      if (lib.inlinedCode != null) libs.add(lib);
    }

    for (var sourceFile in files) {
      var file = info[sourceFile.path];
      _addLibrary(file);
      file.declaredComponents.forEach(_addLibrary);
    }

    // Assert that each file path is unique.
    assert(_uniquePaths(libs));
    return libs;
  }

  bool _uniquePaths(List<LibraryInfo> libs) {
    var seen = new Set();
    for (var lib in libs) {
      if (seen.contains(lib.inlinedCode)) {
        throw new StateError('internal error: '
            'duplicate user code for ${lib.inputPath}. Files were: $files');
      }
      seen.add(lib.inlinedCode);
    }
    return true;
  }

  /**
   * Queue modified Dart files to be written.
   * This will not write files that are handled by [WebComponentEmitter] and
   * [MainPageEmitter].
   */
  void _emitModifiedDartFiles(List<LibraryInfo> libraries) {
    for (var lib in libraries) {
      // Components will get emitted by WebComponentEmitter, and the
      // entry point will get emitted by MainPageEmitter.
      // So we only need to worry about other .dart files.
      if (lib.modified && lib is FileInfo &&
          lib.htmlFile == null && !lib.isEntryPoint) {
        var transaction = _edits[lib.userCode];

        // Save imports that were modified by _fixImports.
        for (var d in lib.userCode.directives) {
          transaction.edit(d.offset, d.end, d.toString());
        }

        if (!lib.userCode.isPart) {
          var pos = lib.userCode.firstPartOffset;
          // Note: we use a different prefix than "autogenerated" to make
          // ChangeRecord unambiguous. Otherwise it would be imported by this
          // and web_ui, resulting in a collision.
          // TODO(jmesserly): only generate this for libraries that need it.
          transaction.edit(pos, pos, "\nimport "
              "'package:web_ui/observe/observable.dart' as __observe;\n");
        }
        _emitFileAndSourceMaps(lib, transaction.commit(), lib.inputPath);
      }
    }
  }

  /**
   * This method computes which Dart files have been modified, starting
   * from [transformed] and marking recursively through all files that import
   * the modified files.
   */
  void _findModifiedDartFiles(List<LibraryInfo> libraries,
      List<FileInfo> transformed) {

    if (transformed.length == 0) return;

    // Compute files that reference each file, then use this information to
    // flip the modified bit transitively. This is a lot simpler than trying
    // to compute it the other way because of circular references.
    for (var lib in libraries) {
      for (var directive in lib.userCode.directives) {
        var importPath = _getDirectivePath(lib, directive);
        if (importPath == null) continue;

        var importInfo = info[importPath];
        if (importInfo != null) {
          importInfo.referencedBy.add(lib);
        }
      }
    }

    // Propegate the modified bit to anything that references a modified file.
    void setModified(LibraryInfo library) {
      if (library.modified) return;
      library.modified = true;
      library.referencedBy.forEach(setModified);
    }
    transformed.forEach(setModified);

    for (var lib in libraries) {
      // We don't need this anymore, so free it.
      lib.referencedBy = null;
    }
  }

  void _fixImports(LibraryInfo library) {
    var fileOutputPath = _pathInfo.outputLibraryPath(library);

    // Fix imports. Modified files must use the generated path, otherwise
    // we need to make the path relative to the input.
    for (var directive in library.userCode.directives) {
      var importPath = _getDirectivePath(library, directive);
      if (importPath == null) continue;
      var importInfo = info[importPath];
      if (importInfo == null) continue;

      String newUri = null;
      if (importInfo.modified) {
        // Use the generated URI for this file.
        newUri = _pathInfo.relativePath(library, importInfo).toString();
      } else if (options.rewriteUrls) {
        // Get the relative path to the input file.
        newUri = _pathInfo.transformUrl(library.inputPath, directive.uri.value);
      }
      if (newUri != null) {
        directive.uri = createStringLiteral(newUri);
      }
    }
  }

  /** Run the analyzer on every input html file. */
  void _analyze() {
    var uniqueIds = new IntIterator();
    for (var file in files) {
      if (file.isHtml) {
        _time('Analyzed contents', file.path, () =>
            analyzeFile(file, info, uniqueIds, _messages));
      }
    }
  }

  /** Emit the generated code corresponding to each input file. */
  void _emit() {
    for (var file in files) {
      if (file.isDart || file.isStyleSheet) continue;
      _time('Codegen', file.path, () {
        var fileInfo = info[file.path];
        cleanHtmlNodes(fileInfo);
        if (!fileInfo.isEntryPoint) {
          // Check all components files for <style> tags and parse the CSS.
          var uriVisitor = new UriVisitor(_pathInfo, _mainPath, fileInfo.path,
              options.rewriteUrls);
          _processStylesheet(uriVisitor, fileInfo, options: options);
        }
        fixupHtmlCss(fileInfo, options);
        _emitComponents(fileInfo);
        if (fileInfo.isEntryPoint) {
          _emitMainDart(file);
          _emitMainHtml(file);
        }
      });
    }

    if (options.processCss) {
      _emitAllCss();
    }
  }

  /** Emit the main .dart file. */
  void _emitMainDart(SourceFile file) {
    var fileInfo = info[file.path];
    var printer = new MainPageEmitter(fileInfo, options.processCss)
        .run(file.document, _pathInfo, _edits[fileInfo.userCode],
            options.rewriteUrls);
    _emitFileAndSourceMaps(fileInfo, printer, fileInfo.inputPath);
  }

  /** Generate an html file with the (trimmed down) main html page. */
  void _emitMainHtml(SourceFile file) {
    var fileInfo = info[file.path];

    var bootstrapName = '${file.path.filename}_bootstrap.dart';
    var bootstrapPath = file.path.directoryPath.append(bootstrapName);
    var bootstrapOutPath = _pathInfo.outputPath(bootstrapPath, '');
    output.add(new OutputFile(bootstrapOutPath, codegen.bootstrapCode(
          _pathInfo.relativePath(new FileInfo(bootstrapPath), fileInfo),
          _useObservers)));

    var document = file.document;
    bool dartLoaderFound = false;
    for (var script in document.queryAll('script')) {
      var src = script.attributes['src'];
      if (src != null && src.split('/').last == 'dart.js') {
        dartLoaderFound = true;
        break;
      }
    }

    // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/templates/index.html#css-additions
    document.head.nodes.insertAt(0, parseFragment(
        '<style>template { display: none; }</style>'));

    if (!dartLoaderFound) {
      document.body.nodes.add(parseFragment(
          '<script type="text/javascript" src="packages/browser/dart.js">'
          '</script>\n'));
    }
    document.body.nodes.add(parseFragment(
      '<script type="application/dart" src="${bootstrapOutPath.filename}">'
      '</script>'
    ));

    for (var link in document.head.queryAll('link')) {
      if (link.attributes["rel"] == "components") {
        link.remove();
      }
    }

    _addAutoGeneratedComment(file);
    output.add(new OutputFile(_pathInfo.outputPath(file.path, '.html'),
        document.outerHtml, source: file.path));
  }

  /** Generate an CSS file for all style sheets (main and components). */
  void _emitAllCss() {
    var allCssBuff = new StringBuffer();
    var mainFile;

    // Emit all linked style sheet files first.
    for (var file in files) {
      var fileInfo = info[file.path];
      if (fileInfo.isEntryPoint) mainFile = file;
      if (file.isStyleSheet) {
        for (var styleSheet in fileInfo.styleSheets) {
          allCssBuff.write(
              '/* ==================================================== */\n'
              '/* Linked style sheet href = ${file.path.filename} */\n'
              '/* ==================================================== */\n');
          allCssBuff.write(emitStyleSheet(styleSheet));
          allCssBuff.write('\n\n');
        }
      }
    }

    // Emit all CSS in each component (style scoped).
    for (var file in files) {
      if (file.isHtml) {
        var fileInfo = info[file.path];
        for (var component in fileInfo.declaredComponents) {
          for (var styleSheet in component.styleSheets) {
            allCssBuff.write(
                '/* ==================================================== */\n'
                '/* Component ${component.tagName} stylesheet */\n'
                '/* ==================================================== */\n');
            allCssBuff.write(emitStyleSheet(styleSheet, component.tagName));
            allCssBuff.write('\n\n');
          }
        }
      }
    }

    var allCss = allCssBuff.toString();
    if (!allCss.isEmpty) {
      var allCssFile = '${mainFile.path.filename}.css';
      var allCssPath = mainFile.path.directoryPath.append(allCssFile);
      var allCssOutPath = _pathInfo.outputPath(allCssPath, '');
      output.add(new OutputFile(allCssOutPath, allCss));
    }
  }

  /** Emits the Dart code for all components in [fileInfo]. */
  void _emitComponents(FileInfo fileInfo) {
    for (var component in fileInfo.declaredComponents) {
      // TODO(terry): Handle one stylesheet per component see fixupHtmlCss.
      if (component.styleSheets.length > 1 && options.processCss) {
        _messages.warning(
            'Component has more than one stylesheet'
            ' - first stylesheet used.', null, file: component.externalFile);
      }
      var printer = new WebComponentEmitter(fileInfo, _messages)
          .run(component, _pathInfo, _edits[component.userCode]);
      _emitFileAndSourceMaps(component, printer, component.externalFile);
    }
  }

  /**
   * Emits a file that was created using [CodePrinter] and it's corresponding
   * source map file.
   */
  void _emitFileAndSourceMaps(
      LibraryInfo lib, CodePrinter printer, Path inputPath) {
    // Bail if we had an error generating the code for the file.
    if (printer == null) return;

    var path = _pathInfo.outputLibraryPath(lib);
    var dir = path.directoryPath;
    printer.add('\n//@ sourceMappingURL=${path.filename}.map');
    printer.build(path.toString());
    output.add(new OutputFile(path, printer.text, source: inputPath));
    // Fix-up the paths in the source map file
    var sourceMap = json.parse(printer.map);
    var urls = sourceMap['sources'];
    for (int i = 0; i < urls.length; i++) {
      urls[i] = new Path(urls[i]).relativeTo(dir).toString();
    }
    output.add(new OutputFile(dir.append('${path.filename}.map'),
          json.stringify(sourceMap)));
  }

  _time(String logMessage, Path path, callback(), {bool printTime: false}) {
    var message = new StringBuffer();
    message.write(logMessage);
    for (int i = (60 - logMessage.length - path.filename.length); i > 0 ; i--) {
      message.write(' ');
    }
    message.write(path.filename);
    return time(message.toString(), callback,
        printTime: options.verbose || printTime);
  }

  void _addAutoGeneratedComment(SourceFile file) {
    var document = file.document;

    // Insert the "auto-generated" comment after the doctype, otherwise IE will
    // go into quirks mode.
    int commentIndex = 0;
    DocumentType doctype = find(document.nodes, (n) => n is DocumentType);
    if (doctype != null) {
      commentIndex = document.nodes.indexOf(doctype) + 1;
      // TODO(jmesserly): the html5lib parser emits a warning for missing
      // doctype, but it allows you to put it after comments. Presumably they do
      // this because some comments won't force IE into quirks mode (sigh). See
      // this link for more info:
      //     http://bugzilla.validator.nu/show_bug.cgi?id=836
      // For simplicity we emit the warning always, like validator.nu does.
      if (doctype.tagName != 'html' || commentIndex != 1) {
        _messages.warning('file should start with <!DOCTYPE html> '
            'to avoid the possibility of it being parsed in quirks mode in IE. '
            'See http://www.w3.org/TR/html5-diff/#doctype',
            doctype.sourceSpan, file: file.path);
      }
    }
    document.nodes.insertAt(commentIndex, parseFragment(
        '\n<!-- This file was auto-generated from ${file.path}. -->\n'));
  }
}

/** Parse all stylesheet for polyfilling assciated with [info]. */
void _processStylesheet(uriVisitor, info, {CompilerOptions options : null}) {
  new _ProcessCss(uriVisitor, options).visit(info);
}

StyleSheet _parseCss(String src, String content, UriVisitor uriVisitor,
                     CompilerOptions options) {
  if (!content.trim().isEmpty) {
    // TODO(terry): Add --checked when fully implemented and error handling.
    var styleSheet = css.parse(content, options:
      [options.warningsAsErrors ? '--warnings_as_errors' : '', 'memory']);
    uriVisitor.visitTree(styleSheet);
    if (options.debugCss) {
      print('\nCSS source: $src');
      print('==========\n');
      print(treeToDebugString(styleSheet));
    }
    return styleSheet;
  }
}

/** Post-analysis of style sheet; parsed ready for emitting with polyfill. */
class _ProcessCss extends InfoVisitor {
  final UriVisitor uriVisitor;
  final CompilerOptions options;
  ComponentInfo component;

  _ProcessCss(this.uriVisitor, this.options);

  void visitComponentInfo(ComponentInfo info) {
    var oldComponent = component;
    component = info;

    super.visitComponentInfo(info);

    component = oldComponent;
  }

  void visitElementInfo(ElementInfo info) {
    if (component != null) {
      var node = info.node;
      if (node.tagName == 'style' && node.attributes.containsKey("scoped")) {
        // Get contents of style tag.
        var content = node.nodes.single.value;
        var styleSheet = _parseCss(component.tagName, content, uriVisitor,
            options);
        if (styleSheet != null) {
          component.styleSheets.add(styleSheet);
        }
      }
    }

    super.visitElementInfo(info);
  }
}
