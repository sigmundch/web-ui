// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compile;

import 'dart:coreimpl';
import 'package:html5lib/dom.dart';
import 'package:html5lib/html5parser.dart';
import 'package:html5lib/tokenizer.dart';

import 'analyzer.dart';
import 'code_printer.dart';
import 'emitters.dart';
import 'file_system.dart';
import 'info.dart';
import 'source_file.dart';
import 'utils.dart';
import 'world.dart';

// TODO(jmesserly): move these things into html5lib's public api
// This is for voidElements:
import 'package:html5lib/src/constants.dart' as html5_constants;
// This is for htmlEscapeMinimal:
import 'package:html5lib/src/utils.dart' as html5_utils;


Document parseHtml(String template, String sourcePath) {
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
  final List<SourceFile> files;

  /** Information about source [files] given their href. */
  final Map<String, FileInfo> info;

  /** Used by template tool to open a file. */
  Compile(this.filesystem)
      : files = <SourceFile>[],
        info = new SplayTreeMap<String, FileInfo>();

  /** Compile the application starting from the given [mainFile]. */
  void run(String mainFile, [String baseDir = ""]) {
    _parseAndDiscover(mainFile, baseDir);
    _analyze();
    _emit();
  }

  /**
   * Parse [mainFile] and recursively discover web components to load and
   * parse.
   */
  void _parseAndDiscover(String mainFile, String baseDir) {
    var pending = new Queue<String>(); // files to process
    pending.addLast(mainFile);
    while (!pending.isEmpty()) {
      var filename = pending.removeFirst();

      // Parse the file.
      if (info.containsKey(filename)) continue;
      var file = _parseFile(filename, baseDir, filename == mainFile);
      files.add(file);

      // Find additional components being loaded.
      var fileInfo = time('Analyzed definitions ${file.filename}',
          () => analyzeDefinitions(file));
      info[file.filename] = fileInfo;
      for (var href in fileInfo.componentLinks) {
        pending.addLast(href);
      }
    }
  }

  /** Parse [filename] and treat it as a component if [isComponent] is true. */
  SourceFile _parseFile(String filename, String baseDir, bool mainDocument) {
    var file = new SourceFile(filename, mainDocument);
    var source = filesystem.readAll("$baseDir/$filename");
    file.document = time("Parsed $filename", () => parseHtml(source, filename));
    if (options.dumpTree) {
      print("\n\n Dump Tree $filename:\n\n");
      print(file.document.outerHTML);
      print("\n=========== End of AST ===========\n\n");
    }
    return file;
  }

  /** Run the analyzer on every input html file. */
  void _analyze() {
    for (var file in files) {
      time('Analyzed contents ${file.filename}', () => analyzeFile(file, info));
    }
  }

  /** Emit the generated code corresponding to each input file. */
  void _emit() {
    for (var file in files) {
      var fileInfo = info[file.filename];
      time('Codegen ${file.filename}', () {
        _removeScriptTags(file.document);
        if (file.mainDocument) {
          fileInfo.generatedCode =
              new MainPageEmitter(fileInfo).run(file.document);
          fileInfo.generatedHtml = _emitMainHtml(file);
        } else {
          fileInfo.generatedCode = emitComponents(fileInfo);
          fileInfo.generatedHtml = _emitComponentHtml(file);
        }
      });
    }
  }


  /** Generate an html file declaring a web component. */
  String _emitComponentHtml(SourceFile file) {
    return "<!-- Generated Web Component from HTML template ${file.filename}."
           "  DO NOT EDIT. -->\n"
           "${file.document.outerHTML}";

  }

  static const String DARTJS_LOADER =
    "http://dart.googlecode.com/svn/branches/bleeding_edge/dart/client/dart.js";

  /** Generate an html file with the (trimmed down) main html page. */
  String _emitMainHtml(SourceFile file) {

    String genDartFile = info[file.filename].dartFilename;

    // Clear the body, we moved all of it
    var body = file.document.body;
    body.nodes.clear();
    body.nodes.add(parseFragment(
        '<script type="text/javascript" src="$DARTJS_LOADER"></script>'
        '<script type="application/dart" src="$genDartFile"></script>'
    ));

    // TODO(terry): These link-rel should be removed once we support generating
    //              components(not using the js_polyfill script).
    var linkParent;
    var links = file.document.queryAll('link');
    for (var link in links) {
      if (link.attributes["rel"] == "components") {
        if (linkParent == null) {
          linkParent = link.parent;
        }
        link.remove();
      }
    }

    // Add all links for any web components used in this application.
    if (linkParent != null) {
      StringBuffer buff = new StringBuffer();
      for (var file in files) {
        var fileInfo = info[file.filename];
        buff.add('<link rel="components" href = "${fileInfo.htmlFilename}">\n');
      }

      linkParent.nodes.add(parseFragment(buff.toString()));
    }
    return "<!-- Generated Web Component from HTML template ${file.filename}."
           "  DO NOT EDIT. -->\n"
           "${file.document.outerHTML}";
  }

  void _removeScriptTags(Document doc) {
    for (var tag in doc.queryAll('script')) {
      if (tag.attributes['type'] == 'application/dart') {
        tag.remove();
      }
    }
  }
}
