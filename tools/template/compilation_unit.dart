// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('compilation_unit');

#import('dart:coreimpl');
#import('package:web_components/tools/lib/world.dart');
#import('package:html5lib/treebuilders/simpletree.dart');
#import('compile.dart');
#import('analyzer.dart');

/** Each html file to process; either main file or web component file. */
class CompilationUnit {
  final String filename;
  final ElemCG elemCG;
  final bool isWebComponent;
  Document document;
  String code;
  String html;
  Map<Node, NodeInfo> info;

  /** Another files to process (e.g., web components). */
  CompilationUnit(this.filename, this.elemCG, [this.isWebComponent = true]);

  bool get opened => document != null;
  bool get codeGenerated => code != null;
  bool get htmlGenerated => html != null;

  String get dartFilename => "$filename.dart";
  String get htmlFilename => "$filename.html";

  String get webComponentName => isWebComponent ? elemCG.webComponentName : "";

  String toString() => "$filename";
}
