// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * **Deprecated**: import 'web_ui/component_build.dart' instead.
 *
 * Common logic to make it easy to create a `build.dart` for your project.
 *
 * The `build.dart` script is invoked automatically by the Editor whenever a
 * file in the project changes. It must be placed in the root of a project
 * (where pubspec.yaml lives) and should be named exactly 'build.dart'.
 *
 * A common `build.dart` would look as follows:
 *
 *     import 'dart:io';
 *     import 'package:web_components/component_build.dart';
 *
 *     main() => build(new Options().arguments, ['web/main.html']);
 *
 *
 */
@deprecated library build_utils;

import 'package:meta/meta.dart';
export 'package:web_ui/component_build.dart';
