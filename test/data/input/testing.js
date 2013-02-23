// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

if (navigator.webkitStartDart) {
  navigator.webkitStartDart();
}

// Webkit is migrating from layoutTestController to testRunner, we use
// layoutTestController as a fallback until that settles in.
var runner = window.testRunner || window.layoutTestController;

if (runner) {
  runner.waitUntilDone();
}

function messageHandler(e) {
  if (e.data == 'done' && runner) {
    runner.notifyDone();
  }
}

window.addEventListener('message', messageHandler, false);

function errorHandler(e) {
  if (runner) {
    window.setTimeout(function() { runner.notifyDone(); }, 0);
  }
  window.console.log('FAIL');
}

window.addEventListener('error', errorHandler, false);
