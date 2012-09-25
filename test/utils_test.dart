// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Tests for some of the utility helper functions used by the compiler. */
library utils_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:web_components/src/template/utils.dart';

main() {
  useVmConfiguration();

  group('toCamelCase', () {
    test('empty', () {
      expect(toCamelCase(''), equals(''));
    });

    test('single token', () {
      expect(toCamelCase('a'), equals('a'));
      expect(toCamelCase('ab'), equals('ab'));
      expect(toCamelCase('Ab'), equals('Ab'));
      expect(toCamelCase('AB'), equals('AB'));
      expect(toCamelCase('long_word'), equals('long_word'));
    });

    test('dashes in the middle', () {
      expect(toCamelCase('a-b'), equals('aB'));
      expect(toCamelCase('a-B'), equals('aB'));
      expect(toCamelCase('A-b'), equals('AB'));
      expect(toCamelCase('long-word'), equals('longWord'));
    });

    test('leading/trailing dashes', () {
      expect(toCamelCase('-hi'), equals('Hi'));
      expect(toCamelCase('hi-'), equals('hi'));
      expect(toCamelCase('hi-friend-'), equals('hiFriend'));
    });

    test('consecutive dashes', () {
      expect(toCamelCase('--hi-friend'), equals('HiFriend'));
      expect(toCamelCase('hi--friend'), equals('hiFriend'));
      expect(toCamelCase('hi-friend--'), equals('hiFriend'));
    });
  });

  group('findEndBrace', () {
    group('no nested braces', () {
      var input = '012 4 67{ 0123 5 }89';
      test('before brace', () {
        expect(findEndBrace(input, 7), equals(-1));
      });

      test('at open brace', () {
        expect(findEndBrace(input, 8), equals(-1));
      });

      test('after open brace', () {
        expect(findEndBrace(input, 9), equals(17));
        expect(findEndBrace(input, 16), equals(17));
      });

      test('at close brace', () {
        expect(findEndBrace(input, 17), equals(17));
      });

      test('after close brace', () {
        expect(findEndBrace(input, 18), equals(-1));
        expect(findEndBrace(input, 48), equals(-1));
      });
    });

    group('nested braces', () {
      var input = '012 4 67{ {{23}5}}89';
      test('before or at first open brace', () {
        expect(findEndBrace(input, 7), equals(-1));
        expect(findEndBrace(input, 8), equals(-1));
      });

      test('after first open brace, before or on second brace', () {
        expect(findEndBrace(input, 9), equals(17));
        expect(findEndBrace(input, 10), equals(17));
      });

      test('after nested brace', () {
        expect(findEndBrace(input, 11), equals(16));
        expect(findEndBrace(input, 12), equals(14));
        expect(findEndBrace(input, 13), equals(14));
        expect(findEndBrace(input, 14), equals(14));
      });

      test('after closing nested braces', () {
        expect(findEndBrace(input, 15), equals(16));
      });
    });
  });
}
