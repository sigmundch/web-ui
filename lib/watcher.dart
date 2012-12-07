// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * **Deprecated**: import 'web_ui/templating.dart' instead.
 *
 * A library to observe changes on Dart objects.
 *
 * Similar to the principle of watchers in AngularJS, this library provides the
 * mechanisms to observe and react to changes that happen in an application's
 * data model.
 *
 * Watchers have a simple lifetime:
 *
 *   * they are created calling [watch],
 *
 *   * they are fired whenever [dispatch] is called and the watched values
 *   changed since the last time [dispatch] was invoked, and
 *
 *   * they are unregistered using a function that was returned by [watch] when
 *   they were created.
 *
 * For example, you can create a watcher that observes changes to a variable by
 * calling [watch] as follows:
 *
 *     var x = 0;
 *     var stop = watch(() => x, (_) => print('hi'));
 *
 * Changes to the variable 'x' will be detected whenever we call [dispatch]:
 *
 *     x = 12;
 *     x = 13;
 *     dispatch(); // the watcher is invoked ('hi' will be printed once).
 *
 * After deregistering the watcher, events are no longer fired:
 *
 *     stop();
 *     x = 14;
 *     dispatch(); // nothing happens.
 *
 * You can watch several kinds of expressions, including lists. See [watch] for
 * more details.
 *
 * A common design pattern for MVC applications is to call [dispatch] at the end
 * of each event loop (e.g. after each UI event is fired). Our view library does
 * this automatically.
 */
@deprecated library watcher;

import 'package:meta/meta.dart';
export 'package:web_ui/watcher.dart';
