// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('source_file');

#import('package:html5lib/treebuilders/simpletree.dart');
#import('compile.dart');
#import('analyzer.dart');

/**
 * An input html file to process by the template compiler; either main file or
 * web component file.
 */
class SourceFile implements Hashable {
  final String filename;
  final bool isWebComponent;
  Document document;

  /** Another files to process (e.g., web components). */
  SourceFile(this.filename, [this.isWebComponent = true]);

  String toString() => "<#SourceFile $filename>";

  int hashCode() => filename.hashCode();
}
