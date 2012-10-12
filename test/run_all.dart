// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is a helper for run.sh. We try to run all of the Dart code in one
 * instance of the Dart VM to reduce warm-up time.
 */
library run_impl;

import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:web_components/dwc.dart' as dwc;
import 'analyzer_test.dart' as analyzer_test;
import 'emitter_test.dart' as emitter_test;
import 'utils_test.dart' as utils_test;
import 'watcher_test.dart' as watcher_test;

// TODO(jmesserly): command line args to filter tests
main() {
  var args = new Options().arguments;
  var pattern = new RegExp(args.length > 0 ? args[0] : '.');

  useVmConfiguration();

  if (pattern.hasMatch('analyzer_test.dart')) analyzer_test.main();
  if (pattern.hasMatch('emitter_test.dart')) emitter_test.main();
  if (pattern.hasMatch('utils_test.dart')) utils_test.main();
  if (pattern.hasMatch('watcher_test.dart')) watcher_test.main();

  // TODO(jmesserly): should have listSync for scripting...
  var lister = new Directory.fromPath(new Path('data/input')).list();
  lister.onFile = (path) {
    if (!path.endsWith('_test.html') || !pattern.hasMatch(path)) return;

    test(path, () => expect(dwc.run(['--verbose', path, 'data/output/']),
        completes));
  };
}
