// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library options;

import 'package:args/args.dart';

class CompilerOptions {
  final bool warningsAsErrors;

  /** True to show informational messages. The `--verbose` flag. */
  final bool verbose;

  /** Remove any generated files. */
  final bool clean;

  final bool useColors;

  final List<String> rest;

  // We could make this faster, if it ever matters.
  factory CompilerOptions() => parse(['']);

  CompilerOptions.fromArgs(ArgResults args)
    : warningsAsErrors = args['warnings_as_errors'],
      verbose = args['verbose'],
      clean = args['clean'],
      useColors = !args['colors'],
      rest = args.rest;

  static CompilerOptions parse(List<String> arguments) {
    var parser = new ArgParser()
      ..addFlag('verbose', help: 'Display detail info', defaultsTo: false)
      ..addFlag('clean', help: 'Remove all generated files', defaultsTo: false)
      ..addFlag('warnings_as_errors', help: 'Warning handled as errors',
          defaultsTo: false)
      ..addFlag('colors', help: 'Display errors/warnings in colored text',
          defaultsTo: true)
      ..addFlag('help', help: 'Displays this help message', defaultsTo: false);

    var results = parser.parse(arguments);
    if (results['help'] || results.rest.length == 0) {
      print('Usage: [options...] sourcefile [outputPath]\n');
      print(parser.getUsage());
      print("   sourcefile - template file filename.html");
      print("   outputPath - if specified directory to generate files; if not");
      print("                same directory as sourcefile");
      return null;
    }

    return new CompilerOptions.fromArgs(results);
  }
}
