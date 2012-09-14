// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('source_file');

#import('package:html5lib/dom.dart');
#import('compile.dart');
#import('analyzer.dart');

/**
 * An input html file to process by the template compiler; either main file or
 * web component file.
 */
class SourceFile {
  final String filename;
  final ElemCG elemCG;
  final bool isWebComponent;
  Document document;
  String code;
  String html;

  /** Generated analysis info for this file. */
  FileInfo info;

  /** Another files to process (e.g., web components). */
  SourceFile(this.filename, this.elemCG, [this.isWebComponent = true]);

  String get dartFilename => "$filename.dart";
  String get htmlFilename => "$filename.html";

  String get webComponentName => isWebComponent ? elemCG.webComponentName : "";

  String toString() => "$filename";
}
