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
  static const int TYPE_MAIN = 1;
  static const int TYPE_COMPONENT = 2;

  final int _fileType;
  final String _filename;
  final ElemCG _ecg;
  Document document;
  String code;
  String _html;
  Map<Node, NodeInfo> info;

  /** Another files to process (e.g., web components). */
  CompilationUnit(String filename, ElemCG ecg, [int fileType = TYPE_COMPONENT])
      : _filename = filename, _fileType = fileType, _ecg = ecg;

  /** Used for processing the main file. */
  CompilationUnit.kickStart(String filename, Document doc, ElemCG ecg)
      : _filename = filename, document = doc, _fileType = TYPE_MAIN,
        _ecg = ecg;

  String get filename() => _filename;
  bool get isWebComponent() => _fileType == TYPE_COMPONENT;

  bool get opened() => document != null;
  bool get codeGenerated() => code != null;
  bool get htmlGenerated() => _html != null;

  ElemCG get elemCG() => _ecg;

  String get html() => _html;
  void set html(String htmlCode) {
    _html = htmlCode;
  }

  String toString() => "$filename";
}
