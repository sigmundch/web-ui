// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Tests for some of the utility helper functions used by the compiler. */
library utils_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:web_components/src/utils.dart';

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
}
