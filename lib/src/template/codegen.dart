// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('codegen');

class Codegen {
  static String header(String filename, String libraryName) => """
// Generated Dart class from HTML template $filename.
// DO NOT EDIT.

#library('${libraryName}');

#import('dart:html');
""";

  static String get commonIncludes => """
#import('package:web_components/js_polyfill/component.dart');
#import('package:web_components/watcher.dart');
#import('package:web_components/js_polyfill/web_components.dart');
#import('package:web_components/src/template/data_template.dart');
""";

  static String emitExtendsClassHeader(String name, String extendsName,
                                       String body) =>
      "\nclass $name extends $extendsName {\n$body\n}\n";
}
