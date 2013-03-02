// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Collects functions to modularly translate the template and web component
 * declarations in a single HTML file.
 * 
 * A Web UI application consistes of multiple HTML and Dart files. A single HTML
 * file can define the top-level page and/or a list of custom elements. Both the
 * page and each custom element can have a Dart library attached to it using a
 * script tag. The code could be inlined in the page or on inlcluded via the
 * 'src' attribute from a separate file.
 *
 * A modular compilation unit of an HTML file consist of a single HTML file and
 * all the Dart libraries that are used directly in the script tags. Any other
 * components that are included via `<link rel="components">` tags or libraries
 * imported from the Dart code can be processed separately.
 */
library web_ui.src.html_compiler;

import 'analyzer.dart';
import 'info.dart';

List<String> readCompilationDependencies(
    SourceFile file, Path sourcePath, Messages messages) {

}

List<String> readRuntimeDependencies(
    SourceFile file, Path sourcePath, Messages messages) {

}

class HtmlTranslationInput {
  String htmlFile;

}

String compile(contents, Map<String, String> ) {
}


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
