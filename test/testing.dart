// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Common definitions used for setting up the test environment. */
library testing;

import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:web_components/src/analyzer.dart';
import 'package:web_components/src/info.dart';
import 'package:web_components/src/messages.dart';
import 'package:web_components/src/options.dart';

useMockMessages() {
  messages = new Messages(printHandler: (message) {});
}

Document parseDocument(String html) => parse(html);

Element parseSubtree(String html) => parseFragment(html).nodes[0];

// TODO(jmesserly): we should always be cleaning HTML...
ElementInfo analyzeElement(Element elem, {bool cleanHtml: false}) {
  return analyzeNode(elem, cleanHtml: cleanHtml).bodyInfo;
}
