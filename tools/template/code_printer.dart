// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('code_printer');

/** Helper class that auto-formats generated code. */
class CodePrinter {
  int _indent;
  StringBuffer _buff;
  CodePrinter([initialIndent = 0])
      : _indent = initialIndent, _buff = new StringBuffer();

  void add(String lines) {
    lines.split('\n').forEach((line) => _add(line.trim()));
  }

  void _add(String line) {
    bool decIndent = line.startsWith("}");
    bool incIndent = line.endsWith("{");
    if (decIndent) _indent--;
    for (int i = 0; i < _indent; i++) _buff.add('  ');
    _buff.add(line);
    _buff.add('\n');
    if (incIndent) _indent++;
  }

  void inc([delta = 1]) { _indent += delta; }
  void dec([delta = 1]) { _indent -= delta; }

  String toString() => _buff.toString();

  int get length => _buff.length;
}
