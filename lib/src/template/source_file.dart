// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_file;

import 'package:html5lib/dom.dart';
import 'info.dart';

/**
 * An input html file to process by the template compiler; either main file or
 * web component file.
 */
class SourceFile implements Hashable {
  final String filename;
  final bool mainDocument;
  Document document;

  /**
   * An HTML file to process. This could be the main html file or a component
   * file.
   */
  SourceFile(this.filename, [this.mainDocument = true]);

  String toString() => "<#SourceFile $filename>";

  int hashCode() => filename.hashCode();
}
