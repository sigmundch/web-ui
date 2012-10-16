// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Common definitions used for setting up the test environment. */
library testing;

import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:web_components/src/template/world.dart';
import 'package:web_components/src/template/source.dart';

// TODO(jmesserly): we need tests for warnings from the analyzer.
class MockWorld extends World {
  MockWorld() : super(null);
  warning(String message, {String filename, SourceSpan span}) {}
  error(String message, {String filename, SourceSpan span}) {}
}

useMockWorld() {
  // TODO(jmesserly): fix the warning system to not need this.
  world = new MockWorld();
}

Element parseSubtree(String html) => parseFragment(html).nodes[0];
