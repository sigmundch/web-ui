// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library directive_parser_test;

import 'package:unittest/unittest.dart';
import 'package:web_ui/src/info.dart' show DartCodeInfo;
import 'package:web_ui/src/messages.dart';
import 'package:web_ui/src/directive_parser.dart';
import 'testing.dart';
import 'compact_vm_config.dart';

main() {
  useCompactVMConfiguration();
  
  var messages;
  setUp() {
    messages = new Messages.silent();
  }
  
  _parse(String code) => parseDartCode(code, null, messages:messages);

  test('empty contents', () {
    var info = _parse('');
    expect(info, isNotNull);
    expect(info.libraryName, isNull);
    expect(info.partOf, isNull);
    expect(info.directives, isEmpty);
    expect(info.code, isEmpty);
  });

  test('no directives, no code', () {
    var code = '/* a comment */\n\n/** another *///foo\n';
    var info = _parse(code);
    expect(info, isNotNull);
    expect(info.libraryName, isNull);
    expect(info.partOf, isNull);
    expect(info.directives, isEmpty);
    expect(info.code, isEmpty);
  });

  test('no directives, some code', () {
    var code = '/* a comment */\n\n/** another *///foo\ncode();';
    var info = _parse(code);
    expect(info, isNotNull);
    expect(info.libraryName, isNull);
    expect(info.partOf, isNull);
    expect(info.directives, isEmpty);
    expect(info.code, equals('code();'));
  });

  test('library, but no directives', () {
    var code = '// a comment\n library foo;\n/* \n\n */ code();\n';
    var info = _parse(code);
    expect(info, isNotNull);
    expect(info.libraryName, equals('foo'));
    expect(info.partOf, isNull);
    expect(info.directives, isEmpty);
    expect(info.code, equals('code();\n'));
  });

  test('directives, but no library', () {
    var code = 'import "url";\n code();\n';
    var info = _parse(code);
    expect(info, isNotNull);
    expect(info.libraryName, isNull);
    expect(info.partOf, isNull);
    expect(info.directives, hasLength(1));
    expect(info.directives[0].uri, equals('url'));
    expect(info.directives[0].prefix, isNull);
    expect(info.directives[0].hide, isNull);
    expect(info.directives[0].show, isNull);
    expect(info.code, equals('code();\n'));
  });

  test('import with multiple strings', () {
    var code = 'import "url"\n"foo";';
    var info = _parse(code);
    expect(info.directives, hasLength(1));
    expect(info.directives[0].uri, equals('urlfoo'));
  });

  test('directives, no prefix', () {
    var code = 'library foo.bar; import \'url2\';\n'
      'export \'foo.dart\';\npart "part.dart";\n code();\n';
    var info = _parse(code);
    expect(info, isNotNull);
    expect(info.libraryName, equals('foo.bar'));
    expect(info.partOf, isNull);
    expect(info.directives, hasLength(3));
    expect(info.directives[0].label, equals('import'));
    expect(info.directives[0].uri, equals('url2'));
    expect(info.directives[0].prefix, isNull);
    expect(info.directives[0].hide, isNull);
    expect(info.directives[0].show, isNull);
    expect(info.directives[1].label, equals('export'));
    expect(info.directives[1].uri, equals('foo.dart'));
    expect(info.directives[1].prefix, isNull);
    expect(info.directives[1].hide, isNull);
    expect(info.directives[1].show, isNull);
    expect(info.directives[2].label, equals('part'));
    expect(info.directives[2].uri, equals("part.dart"));
    expect(info.code, equals('code();\n'));
  });

  test('part-of, but no directives', () {
    var code = '/* ... */ part of foo.bar;\n/* \n\n */ code();\n';
    var info = _parse(code);
    expect(info, isNotNull);
    expect(info.libraryName, isNull);
    expect(info.partOf, equals('foo.bar'));
    expect(info.directives, isEmpty);
    expect(info.code, equals('code();\n'));
  });

  test('directives with prefix', () {
    var code = 'library f;'
      'import "a1.dart" as first;\n'
      'import "a2.dart" as second;\n'
      'import "a3.dart" as i3;\n'
      'code();\n';
    var info = _parse(code);
    expect(info, isNotNull);
    expect(info.libraryName, equals('f'));
    expect(info.partOf, isNull);
    expect(info.directives, hasLength(3));
    expect(info.directives[0].label, equals('import'));
    expect(info.directives[0].uri, equals('a1.dart'));
    expect(info.directives[0].prefix, equals('first'));
    expect(info.directives[0].hide, isNull);
    expect(info.directives[0].show, isNull);
    expect(info.directives[1].label, equals('import'));
    expect(info.directives[1].uri, equals('a2.dart'));
    expect(info.directives[1].prefix, equals('second'));
    expect(info.directives[1].hide, isNull);
    expect(info.directives[1].show, isNull);
    expect(info.directives[2].label, equals('import'));
    expect(info.directives[2].uri, equals('a3.dart'));
    expect(info.directives[2].prefix, equals('i3'));
    expect(info.directives[2].hide, isNull);
    expect(info.directives[2].show, isNull);
    expect(info.code, equals('code();\n'));
  });

  test('directives with combinators', () {
    var code = 'library f;'
      'import "a1.dart" as a1 show one, two hide bar;\n'
      'export "a2.dart" show a, b, c hide d, e;\n'
      'code();\n';
    var info = _parse(code);
    expect(info, isNotNull);
    expect(info.libraryName, equals('f'));
    expect(info.partOf, isNull);
    expect(info.directives, hasLength(2));
    expect(info.directives[0].label, equals('import'));
    expect(info.directives[0].uri, equals('a1.dart'));
    expect(info.directives[0].prefix, equals('a1'));
    expect(info.directives[0].hide, equals(['bar']));
    expect(info.directives[0].show, equals(['one', 'two']));
    expect(info.directives[1].label, equals('export'));
    expect(info.directives[1].uri, equals('a2.dart'));
    expect(info.directives[1].prefix, isNull);
    expect(info.directives[1].hide, equals(['d', 'e']));
    expect(info.directives[1].show, equals(['a', 'b', 'c']));
    expect(info.code, equals('code();\n'));
  });  
}


