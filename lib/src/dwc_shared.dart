// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Shared functionality used by command line and dartium dwc frontends.
 * Once dart:io dependencies are all abstracted out into
 * src/tempalte/file_system this file can go away and dwc.dart can be used
 * by both command line and dartium frontends.
 */
library dwc_shared;

import 'package:args/args.dart';
import 'cmd_options.dart';
import 'file_system.dart';
import 'file_system/memory.dart';
import 'world.dart';

ArgParser commandOptions() {
  return new ArgParser()
    ..addFlag('verbose', help: 'Display detail info', defaultsTo: false)
    ..addFlag('clean', help: 'Remove all generated files', defaultsTo: false)
    ..addFlag('dump', help: 'Dump AST', defaultsTo: false)
    ..addFlag('suppress_warnings', help: 'Warnings not displayed',
        defaultsTo: true)
    ..addFlag('warnings_as_errors', help: 'Warning handled as errors',
        defaultsTo: false)
    ..addFlag('throw_on_errors', help: 'Throw on errors encountered',
        defaultsTo: false)
    ..addFlag('throw_on_warnings', help: 'Throw on warnings encountered',
        defaultsTo: false)
    ..addFlag('no_colors', help: 'Display errors/warnings in colored text',
        defaultsTo: true)
    ..addFlag('help', help: 'Displays this help message', defaultsTo: false);
}

void initHtmlWorld(CmdOptions opts) {
  var fs = new MemoryFileSystem();
  initializeWorld(fs, opts);

  // TODO(terry): Should be set by arguments.  When run as a tool these aren't
  // set when run internaly set these so we can compile CSS and catch any
  // problems programmatically.
  //  options.throwOnErrors = true;
  //  options.throwOnFatal = true;
  //  options.useColors = commandLine ? true : false;
}
