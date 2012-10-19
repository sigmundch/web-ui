// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Common definitions used for setting up the test environment. */
library testing;

import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';
import 'package:html5lib/parser.dart';
import 'package:web_components/src/messages.dart';
import 'package:web_components/src/options.dart';

useMockMessages() {
  messages = new Messages(printHandler: (message) {});
}

Element parseSubtree(String html) => parseFragment(html).nodes[0];
