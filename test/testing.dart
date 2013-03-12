// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Common definitions used for setting up the test environment. */
library testing;

import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:web_ui/src/analyzer.dart';
import 'package:web_ui/src/info.dart';
import 'package:web_ui/src/messages.dart';
import 'package:web_ui/src/options.dart';
import 'package:web_ui/src/files.dart';
import 'package:web_ui/src/utils.dart';


Document parseDocument(String html) => parse(html);

Element parseSubtree(String html) => parseFragment(html).nodes[0];

ElementInfo analyzeElement(Element elem, Messages messages) {
  var fileInfo = analyzeNodeForTesting(elem, messages);
  return fileInfo.bodyInfo;
}

FileInfo analyzeDefinitionsInTree(Document doc, Messages messages,
    {String packageRoot: 'packages'}) {

  return analyzeDefinitions(new SourceFile('')..document = doc,
      packageRoot, messages);
}

/** Parses files in [fileContents], with [mainHtmlFile] being the main file. */
List<SourceFile> parseFiles(Map<String, String> fileContents,
    [String mainHtmlFile = 'index.html']) {

  var result = <SourceFile>[];
  fileContents.forEach((filename, contents) {
    var src = new SourceFile(filename);
    src.document = parse(contents);
    result.add(src);
  });

  return result;
}

/** Analyze all files. */
Map<String, FileInfo> analyzeFiles(List<SourceFile> files,
    {Messages messages, String packageRoot: 'packages'}) {
  messages = messages == null ? new Messages.silent() : messages;
  var result = new Map<String, FileInfo>();

  // analyze definitions
  for (var file in files) {
    result[file.path] = analyzeDefinitions(file, packageRoot, messages);
  }

  // analyze file contents
  var uniqueIds = new IntIterator();
  for (var file in files) {
    analyzeFile(file, result, uniqueIds, messages);
  }
  return result;
}
