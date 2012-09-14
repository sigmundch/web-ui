// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * TodoMVC sample application written with web-components and manually bound
 * models. This example illustrates what the executable code would look like for
 * an application written using Dart-adapted MDV-style templates. It can also be
 * used as a guideline for how our tools will generate code from the template
 * input.
 *
 * See the sibling 'input' directory to visualize what users would write to get
 * the code (manually) generated here.
 */
#library('todo');

#import('dart:html');
#import('model.dart');
#import('package:web_components/watcher.dart');

main() {
  // listen on changes to #hash in the URL
  window.on.popState.add((_) {
    viewModel.showIncomplete = window.location.hash != '#/completed';
    viewModel.showDone = window.location.hash != '#/active';
    dispatch();
  });
}
