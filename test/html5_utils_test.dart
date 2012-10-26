// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests that we are generating a valid `dart:html` type for each element
 * field. This test is a bit goofy because it needs to run the `dart_analyzer`,
 * but I can't think of an easier way to validate that the HTML types in our
 * table exist.
 */
library html_type_test;

import 'dart:io';
import 'package:html5lib/dom.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:web_components/src/html5_utils.dart';
import 'testing.dart';

main() {
  useVmConfiguration();
  useMockMessages();

  test('types are in dart:html', () {
    var code = new StringBuffer();
    code.add('import "dart:html" as html;\n');
    htmlElementNames.forEach((tag, className) {
      code.add('html.$className _$tag;\n');
    });

    const generatedFile = 'data/output/html5_utils_test_generated.dart';
    new File(generatedFile).openSync(FileMode.WRITE)
        ..writeStringSync(code.toString())
        ..close();

    // TODO(jmesserly): it would be good to run all of our
    // dart_analyzer tests in one batch.
    Process.run('dart_analyzer', '--fatal-warnings --fatal-type-errors '
        '--work data/output/analyzer/ $generatedFile'.split(' '))
        .then(expectAsync1((result) {
      expect(result.stdout, '', result.stdout);
      expect(result.stderr, '', result.stderr);
      expect(result.exitCode, 0, 'expected success, but got exit code '
          '${result.exitCode}');
    }));
  });
}
