// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * TodoMVC sample application written with web-components and manually bound
 * models. This example uses mirrors to implements Dart-adapted MDV templates.
 */
#library('output_todo');

#import('dart:html');

// Code from components
// TODO(jmesserly): ideally these would be package: imports

#import('model.dart');
#import("package:web_components/watcher.dart");
#import("package:web_components/mirror_polyfill/web_components.dart");

main() {
  initializeComponents(viewModel);

  // listen on changes to #hash in the URL
  window.on.popState.add((_) {
    viewModel.showIncomplete = window.location.hash != '#/completed';
    viewModel.showDone = window.location.hash != '#/active';
    dispatch();
  });
}
