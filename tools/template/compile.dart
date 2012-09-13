// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('compile');

#import('package:html5lib/html5parser.dart');
#import('package:html5lib/tokenizer.dart');
#import('package:html5lib/treebuilders/simpletree.dart');
#import('package:web_components/tools/lib/file_system.dart');
#import('package:web_components/tools/lib/world.dart');

#import('analyzer.dart', prefix: 'analyzer');
#import('code_printer.dart');
#import('codegen_application.dart');
#import('codegen_component.dart');
#import('emitters.dart');
#import('source_file.dart');
#import('utils.dart');

// TODO(jmesserly): move these things into html5lib's public api
// This is for voidElements:
#import('package:html5lib/lib/constants.dart', prefix: 'html5_constants');
// This is for htmlEscapeMinimal:
#import('package:html5lib/lib/utils.dart', prefix: 'html5_utils');


// TODO(terry): Too many classes in this file need to break up walking, analysis
//              and codegen to different files (started but needs to finished).
// TODO(terry): Add obfuscation mapping file.
parseHtml(String template, String sourcePath) {
  var parser = new HTMLParser();
  var document = parser.parse(new HTMLTokenizer(template));

  // Note: errors aren't fatal in HTML (unless strict mode is on).
  // So just print them as warnings.
  for (var e in parser.errors) {
    world.warning('$sourcePath line ${e.line}:${e.column}: ${e.message}');
  }
  return document;
}

/**
 * Walk the tree produced by the parser looking for templates, expressions, etc.
 * as a prelude to emitting the code for the template.
 */
class Compile {
  final FileSystem filesystem;
  final String baseDir;
  final List<SourceFile> files;

  /** Used by template tool to open a file. */
  Compile(this.filesystem, String filename, [this.baseDir = ""])
      : files = <SourceFile>[] {
    _parseAndLoadFiles(filename);
    _analizeAllFiles();
    _emitAll();
  }

  void _parseAndLoadFiles(String mainFile) {
    var pending = new Queue<String>(); // files to process
    var parsed = new Set<String>();
    pending.addLast(mainFile);
    while (!pending.isEmpty()) {
      var filename = pending.removeFirst();

      // Parse the file.
      if (parsed.contains(filename)) continue;
      parsed.add(filename);
      var file = _parseFile(filename, filename != mainFile);

      // Find additional components being loaded.
      file.document.queryAll('link').forEach((elem) {
        if (elem.attributes['rel'] == 'components') {
          var href = elem.attributes['href'];
          if (href == null || href == '') {
            world.error(
              "invalid webcomponent reference:\n ${elem.outerHTML}");
          } else {
            pending.addLast(href);
          }
        }
      });
    }
  }

  /** Parse [filename] and treat it as a component if [isComponent] is true. */
  SourceFile _parseFile(String filename, bool isComponent) {
    var file = _createFile(filename, isComponent);
    files.add(file);
    var source = filesystem.readAll("$baseDir/$filename");
    file.document = time("Parsed $filename", () => parseHtml(source, filename));
    if (options.dumpTree) {
      print("\n\n Dump Tree $filename:\n\n");
      print(file.document.outerHTML);
      print("\n=========== End of AST ===========\n\n");
    }
    return file;
  }

  SourceFile _createFile(String filename, bool isWebComponent) {
    var ecg = new ElemCG();
    var file = new SourceFile(filename, ecg, isWebComponent);
    ecg.file = file;
    return file;
  }

  /** Run the analyzer on every input html file. */
  void _analizeAllFiles() {
    for (var file in files) {
      file.info = time('Analyzed ${file.filename}',
          () => analyzer.analyze(file.document));
    }
  }

  /** Emit the generated code corresponding to each input file. */
  void _emitAll() {
    // TODO(sigmund): simplify walker
    for (var file in files) {
      time('Walked ${file.filename}',
          () => _walkTree(file.document, file.elemCG));
    }

    for (var file in files) {
      time('Codegen ${file.filename}', () {
        file.code = _emitter(file);
        var html = _emitterHTML(file);
        file.html =
          "<!-- Generated Web Component from HTML template ${file.filename}."
          "  DO NOT EDIT. -->\n"
          "$html";
      });
    }
  }

  /** Walk the HTML tree of the template file. */
  void _walkTree(Document doc, ElemCG ecg) {
    if (!ecg.pushBlock()) {
      world.error("Error at ${doc.nodes}");
    }

    // Start from the HTML node.
    var start = doc.query('html');

    bool firstTime = true;
    for (var child in start.nodes) {
      if (child is Text) {
        if (!firstTime) {
          ecg.closeStatement();
        }

        // Skip any empty text nodes; no need to pollute the pretty-printed
        // HTML.
        // TODO(terry): Need to add {space}, {/r}, etc. like Soy.
        String textNodeValue = child.value.trim();
        if (textNodeValue.length > 0) {
          CGStatement stmt = ecg.pushStatement(child, "frag");
        }
        continue;
      }

      ecg.emitConstructHtml(child, "", "frag");
      firstTime = false;
    }
  }

  /** Emit the Dart code. */
  String _emitter(SourceFile file) {
    var libraryName = file.filename.replaceAll('.', '_');

    if (file.isWebComponent) {
      return CodegenComponent.generate(libraryName, file.filename, file.elemCG);
    } else {
      return CodegenApplication.generate(file.document, files, libraryName,
          file.filename, file.elemCG);
    }
  }

  String _emitterHTML(SourceFile file) {

    // TODO(jmesserly): not sure about removing script nodes like this
    // But we need to do this for web components to work.
    var scriptTags = file.document.queryAll('script');
    for (var tag in scriptTags) {
      // TODO(jmesserly): use tag.remove() once it's supported.
      tag.parent.$dom_removeChild(tag);
    }

    if (file.isWebComponent) {
      return file.document.outerHTML;
    } else {
      return CodegenApplication.generateHTML(file.document, files);
    }
  }
}


/**
 * CodeGen block used for a set of statements to be emited wrapped around a
 * template control that implies a block (e.g., iterate, with, etc.).  The
 * statements (HTML) within that block are scoped to a CGBlock.
 */
class CGBlock {
  final List<CGStatement> _stmts;

  /** Local variable index (e.g., e0, e1, etc.). */
  int _localIndex;

  // TODO(jmesserly): these are dead now?
  final analyzer.TemplateInfo templateInfo;
  final Element templateElement;
  final SourceFile file;

  CGBlock(SourceFile file, [Element templateElement])
      : file = file,
        templateElement = templateElement,
        templateInfo = (templateElement != null &&
            templateElement is analyzer.TemplateInfo ?
            file.info.elements[templateElement] : null),
        _stmts = <CGStatement>[],
        _localIndex = 0;

  bool get hasStatements => !_stmts.isEmpty();
  bool get isConstructor => templateInfo == null;
  bool get isTemplate => templateInfo != null;

  /**
   * Each statement (HTML) encountered is remembered with either/both variable
   * name of parent and local name to associate with this element when the DOM
   * constructed.
   */
  CGStatement push(elem, parentName, [bool exact = false]) {
    // TODO(jmesserly): fix this int|String union type.
    var varName;
    analyzer.ElementInfo info = file.info.elements[elem];
    if (info != null) varName = info.idAsIdentifier;

    if (varName == null) {
      varName = _localIndex++;
    }

    var s = new CGStatement(elem, info, parentName, varName, exact);
    _stmts.add(s);
    return s;
  }

  void add(String value) {
    if (_stmts.last() != null) {
      _stmts.last().add(value);
    }
  }

  CGStatement get last => _stmts.length > 0 ? _stmts.last() : null;

  /**
   * Emit the entire component class.
   */
  String webComponentCode(ElemCG ecg, String constructorSignature) {
    var emitter = new WebComponentEmitter(file.info, constructorSignature);
    return emitter.run(file.document);
  }

  const String _ITER_KEYWORD = " in ";
  String emitTemplateIterate(CodePrinter out, int index) {
    if (templateInfo.hasIterate) {
      String varName = "xList_$index";
      out.add("var $varName = manager[body.query("
          "'#${templateInfo.elementId}')];");
      // TODO(terry): Use real Dart expression parser.
      String listExpr = templateInfo.loopVariable;
      int inIndex = listExpr.indexOf(_ITER_KEYWORD);
      if (inIndex != -1) {
        listExpr = listExpr.substring(inIndex + _ITER_KEYWORD.length).trim();
      }
      // TODO(terry): Should return error or allow just app.todos?
      out.add("$varName.items = () => $listExpr;");
    }
  }
}

// TODO(terry): Consider adding backpointer to block CGStatement is contained
//              in; no need to replicate things; like whether the statement is
//              in a repeat block (e.g., _repeating).
/**
 * CodeGen Statement used to manage each statement to be emited.  CGStatement
 * has the HTML (_elem) as well as the variable name of the parent element and
 * the varName (variable name) to be used to create this DOM element.
 */
class CGStatement {
  final bool _repeating;
  final StringBuffer _buff;
  Node _elem;
  analyzer.ElementInfo _info;
  final parentName;
  String variableName;
  bool _globalVariable;
  bool _closed;

  CGStatement(this._elem, this._info, this.parentName, varNameOrIndex,
      [bool exact = false, bool repeating = false])
      : _buff = new StringBuffer(),
        _closed = false,
        _repeating = repeating {

    if (varNameOrIndex is String) {
      // We have the global variable name
      variableName = varNameOrIndex;
      _globalVariable = true;
    } else {
      // local index generate local variable name.
      variableName = "_e${varNameOrIndex}";
      _globalVariable = false;
    }
  }

  bool get hasGlobalVariable => _globalVariable;

  void add(String value) {
    _buff.add(value);
  }

  bool get closed => _closed;

  void close() {
    if (_elem is Element && _elem is! DocumentType &&
        html5_constants.voidElements.indexOf(_elem.tagName) >= 0) {
      add("</${_elem.tagName}>");
    }
    _closed = true;
  }

  String emitStatement(int boundElemIdx) {
    var printer = new CodePrinter();

    String localVar = "";
    String tmpRepeat;
    if (hasGlobalVariable) {
      if (_repeating) {
        tmpRepeat = "tmp_${variableName}";
        localVar = "var ";
      }
    } else {
      localVar = "var ";
    }

    /* Emiting the following code fragment where varName is the attribute
       value for var=

          varName = new Element.html('HTML GOES HERE');
          parent.nodes.add(varName);

       for repeating elements in a #each:

          var tmp_nnn = new Element.html('HTML GOES HERE');
          varName.add(tmp_nnn);
          parent.nodes.add(tmp_nnn);

       for elements w/o var attribute set:

          var eNNN = new Element.html('HTML GOES HERE');
          parent.nodes.add(eNNN);
    */
    printer.add("");
    if (hasDataBinding) {
      // TODO(sigmund, terry): is this still needed?
      // printer.add("$spaces$localVar$varName = renderSetupFineGrainUpdates("
      //               "() => model.${exprs[0].name}, $boundElemIdx);\n");
    } else {
      bool isTextNode = _elem is Text;
      String createType = isTextNode ? "Text" : "Element.html";
      if (tmpRepeat == null) {
        printer.add("$localVar$variableName = new $createType(\'");
      } else {
        printer.add("$localVar$tmpRepeat = new $createType(\'");
      }
      if (_elem.tagName == 'template') {
        printer.add("<template></template>");
      } else {
        printer.add(isTextNode ?  _buff.toString().trim() : _buff.toString());
      }
      printer.add("\');\n");
    }

    if (tmpRepeat == null) {
      printer.add("$parentName.nodes.add($variableName);\n");
      if (_elem.tagName == 'template') {
        // TODO(terry): Need to support multiple templates either nested or
        //              siblings.
        // Hookup analyzer.TemplateInfo to the root.
        printer.add("root = $parentName;\n");
      }
    } else {
      printer.add("$parentName.nodes.add($tmpRepeat);\n"
                  "$variableName.add($tmpRepeat);\n");
    }

    return printer.toString();
  }

  bool get hasDataBinding => _info != null && _info.hasDataBinding;
}


// TODO(terry): Consider merging ElemCG and Analyze.
/**
 * Code that walks the HTML tree.
 */
class ElemCG {
  // TODO(terry): Hacky, need to replace with real expression parser.
  /** List of identifiers and quoted strings (single and double quoted). */
  var identRe = const RegExp(
      @"""s*('"\'\"[^'"\'\"]+'"\'\"|[_A-Za-z][_A-Za-z0-9]*)""");

  bool _webComponent;

  /** Name of class if web component constructor attribute of element tag. */
  String _className;

  /** Name of the web component name attribute of element tag. */
  String _webComponentName;

  /** List of script tags with src. */
  final List<String> _includes;

  /** Dart script code associated with web component. */
  String _userCode;

  final List<CGBlock> _cgBlocks;

  /** Global List var initializtion for all blocks in a #each. */
  final StringBuffer _globalInits;

  /**  List of each function declarations. */
  final List<String> repeats;

  /** Input file associated with this emitter. */
  SourceFile file;

  ElemCG()
      : _webComponent = false,
        _includes = [],
        repeats = [],
        _cgBlocks = [],
        _globalInits = new StringBuffer();

  bool get isWebComponent => _webComponent;
  String get className => _className;
  String get webComponentName => _webComponentName;
  List<String> get includes => _includes;
  String get userCode => _userCode;

  void reportError(String msg) {
    world.error("${file.filename}: $msg");
  }

  CGBlock templateCG(int index) {
    if (index > 0) {
      return getCGBlock(index);
    }
  }

  bool pushBlock([Element templateElement]) {
    _cgBlocks.add(new CGBlock(file, templateElement));
    return true;
  }

  CGStatement pushStatement(var elem, var parentName) {
    return lastBlock.push(elem, parentName);
  }

  bool get closedStatement {
    return (lastBlock != null && lastBlock.last != null) ?
        lastBlock.last.closed : false;
  }

  void closeStatement() {
    if (lastBlock != null && lastBlock.last != null &&
        !lastBlock.last.closed) {
      lastBlock.last.close();
    }
  }

  String get lastVariableName {
    if (lastBlock != null && lastBlock.last != null) {
      return lastBlock.last.variableName;
    }
  }

  String get lastParentName {
    if (lastBlock != null && lastBlock.last != null) {
      return lastBlock.last.parentName;
    }
  }

  CGBlock get lastBlock => _cgBlocks.length > 0 ? _cgBlocks.last() : null;

  void add(String str) {
    _cgBlocks.last().add(str);
  }

  CGBlock getCGBlock(int idx) => idx < _cgBlocks.length ? _cgBlocks[idx] : null;

  final String _DART_SCRIPT_TYPE = "application/dart";

  void emitScript(Element elem) {
    Expect.isTrue(elem.tagName == 'script');

    if (elem.attributes['type'] == _DART_SCRIPT_TYPE) {
      String includeName = elem.attributes["src"];
      if (includeName != null) {
        _includes.add(includeName);
      } else {
        Expect.isTrue(elem.nodes.length == 1);
        // This is the code to be emitted with the web component.
        _userCode = elem.nodes[0].value;
      }
    } else {
      reportError('tag ignored possibly missing type="$_DART_SCRIPT_TYPE"');
    }
  }

  /**
   * [scopeName] for expression.
   * [parentVarOrIndex] if # it's a local variable if string it's an exposed
   * name (specified by the var attribute) for this element.
   */
  emitElement(Node elem,
              [String scopeName = "",
               var parentVarOrIdx = 0,
               bool immediateNestedRepeat = false]) {
    if (elem.tagName == 'template') {
      emitTemplate(elem);
    } else if (elem is Element) {
      // Note: this check is always true right now, because DocumentFragment
      // does not extend Element in html5lib. This might change in the future
      // because in dart:html DocumentFragment extends Element
      // (this is unlike the real DOM, see:
      // http://www.w3.org/TR/DOM-Level-2-Core/core.html#ID-B63ED1A3).
      if (elem is! DocumentFragment) {
        // TODO(jmesserly): would be nice if we didn't have to grab info here.
        var info = file.info.elements[elem];
        add("<${elem.tagName}${attributesToString(elem, info)}>");
      }
      String prevParent = lastVariableName;
      for (var childElem in elem.nodes) {
        if (childElem is Element) {
          closeStatement();
          emitConstructHtml(childElem, scopeName, prevParent);
          closeStatement();
        } else {
          emitElement(childElem, scopeName, parentVarOrIdx);
        }
      }

      // Close this tag.
      closeStatement();
    } else if (elem is Text) {
      String outputValue = elem.value.trim();
      if (outputValue.length > 0) {
        bool emitTextNode = false;
        if (closedStatement) {
          String prevParent = lastParentName;
          CGStatement stmt = pushStatement(elem, prevParent);
          emitTextNode = true;
        }

        // TODO(terry): Need to interpolate following:
        //      {sp}  → space
        //      {nil} → empty string
        //      {\r}  → carriage return
        //      {\n}  → new line (line feed)
        //      {\t}  → tab
        //      {lb}  → left brace
        //      {rb}  → right brace

        add("${outputValue}");            // remove leading/trailing whitespace.

        if (emitTextNode) {
          closeStatement();
        }
      }
    }
  }

  // TODO(terry): Hack prefixing all names with "${scopeName}." but don't touch
  //              quoted strings.
  String _resolveNames(String expr, String prefixPart) {
    StringBuffer newExpr = new StringBuffer();
    Iterable<Match> matches = identRe.allMatches(expr);

    int lastIdx = 0;
    for (Match m in matches) {
      if (m.start() > lastIdx) {
        newExpr.add(expr.substring(lastIdx, m.start()));
      }

      bool identifier = true;
      if (m.start() > 0)  {
        int charCode = expr.charCodeAt(m.start() - 1);
        // Starts with ' or " then it's not an identifier.
        identifier = charCode != 34 /* " */ && charCode != 39 /* ' */;
      }

      String strMatch = expr.substring(m.start(), m.end());
      if (identifier) {
        newExpr.add("${prefixPart}.${strMatch}");
      } else {
        // Quoted string don't touch.
        newExpr.add("${strMatch}");
      }
      lastIdx = m.end();
    }

    if (expr.length > lastIdx) {
      newExpr.add(expr.substring(lastIdx));
    }

    return newExpr.toString();
  }

  // TODO(terry): Might want to optimize if the other top-level nodes have no
  //              control structures (with, each, if, etc.). We could
  //              synthesize a root node and create all the top-level nodes
  //              under the root node with one innerHTML.
  /**
   * Construct the HTML; each top-level node get's it's own variable.
   */
  void emitConstructHtml(Node elem,
                         [String scopeName = "",
                          String parentName = "parent",
                          int varIndex = 0,
                          bool immediateNestedRepeat = false]) {
    if (elem is Element) {
      if (elem.tagName == "element") {
        _webComponent = true;

        String className = elem.attributes["constructor"];
        if (className != null) {
          _className = className;
        } else {
          reportError(
              "Web Component class name missing; use constructor attribute");
        }

        String wcName = elem.attributes["name"];
        if (wcName != null) {
          _webComponentName = wcName;
        } else {
          reportError("Missing name of Web Component use name attribute");
        }

        CGStatement stmt = pushStatement(elem, parentName);
        emitElement(elem, scopeName, stmt.hasGlobalVariable ?
            stmt.variableName : varIndex);
      } else if (elem.tagName == 'script') {
        // Never emit a script tag.
        emitScript(elem);
      } else if (elem.tagName == 'link') {
        // Nothing to do.
      } else {
        CGStatement stmt = pushStatement(elem, parentName);
        emitElement(elem, scopeName, stmt.hasGlobalVariable ?
            stmt.variableName : varIndex);
      }
    } else {
      // Text node.
      emitElement(elem, scopeName, varIndex, immediateNestedRepeat);
    }
  }

  /**
   * Any references to products.sales needs to be remaped to item.sales
   * for now it's a hack look for first dot and replace with item.
   */
  String repeatIterNameToItem(String iterName) {
    String newName = iterName;
    var dotForIter = iterName.indexOf('.');
    if (dotForIter >= 0) {
      newName = "_item${iterName.substring(dotForIter)}";
    }

    return newName;
  }

  void emitTemplate(Element elem) {
    if (!pushBlock(elem)) {
      reportError("Error at ${elem}");
    }

    for (var child in elem.nodes) {
      emitConstructHtml(child, "e0", "templateRoot");
    }
  }
}

// TODO(jmesserly): is there a better way to do this?
String attributesToString(Node node, analyzer.ElementInfo info) {
  if (node.attributes.length == 0) return '';

  var str = new StringBuffer();
  node.attributes.forEach((name, value) {
    // Skip data bound attributes, we'll deal with them separately.
    if (info.attributes[name] == null) {
      // TODO(jmesserly): need a convenience method in html5lib for escaping
      // html attributes.
      // Note: we don't use dart's htmlEscape function because it escapes more
      // things than we need. This is the same one used by html5lib.
      value = html5_utils.htmlEscapeMinimal(value, {'"': "&quot;"});
      str.add(' $name="$value"');
    }
  });
  return str.toString();
}
