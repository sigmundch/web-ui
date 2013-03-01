// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Collects functions to processes html files modularly. */
library web_ui.src.html_compiler;

import 'analyzer.dart';
import 'info.dart';

List<String> readDependencies(
    SourceFile file, Path sourcePath, Messages messages) {

}

String compile(contents) {
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
