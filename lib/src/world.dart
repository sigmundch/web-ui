// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library world;

import 'package:html5lib/dom_parsing.dart';
import 'utils.dart';

/** The one true [World]. */
World world;

/** General options used by the tool (CSS or template). */
var options;

typedef void PrintHandler(String message);

/**
 * Should be called exactly once to setup singleton world.
 * Can use world.reset() to reinitialize.
 */
void initializeWorld(var files, var opts) {
  options = opts;
  world = new World(files);
  world.init();
}

/** Default [PrintHandler]. */
void _defaultPrintHandler(String message) {
  print(message);
}

/** Can be thrown on any compiler error and includes source location. */
class CompilerException implements Exception {
  final String _message;
  final String _filename;
  final SourceSpan _location;

  CompilerException(this._message, [this._filename, this._location]);

  String toString() {
    if (_location != null && _filename != null) {
      return 'CompilerException: '
        '${_location.toMessageString(filename, _message)}';
    } else {
      return 'CompilerException: $_message';
    }
  }
}

/** Represents a Dart template "world". */
class World {
  String template;

  var files;

  int errors = 0, warnings = 0;
  bool seenFatal = false;
  PrintHandler printHandler = _defaultPrintHandler;

  World(this.files);

  void reset() {
    errors = warnings = 0;
    seenFatal = false;
    init();
  }

  init() {
  }

  void _message(String color, String prefix, String message,
      {SourceSpan span, String filename, bool throwing: false}) {
    var output = new StringBuffer();

    output.add(options.useColors ?
      '${color}${prefix}${NO_COLOR}' : '${prefix}');

    output.add(filename != null ? '${filename}: ' : '');
    output.add(message);

    output.add(span != null ? '\n${span.toMessageString}' : '');

    printHandler('${output.toString()}');

    if (throwing) {
      throw new CompilerException('${prefix}${message}', filename, span);
    }
  }

  /** [message] is considered a static compile-time error by the Dart lang. */
  void error(String message, {String filename, SourceSpan span}) {
    errors++;
    _message(RED_COLOR, 'error: ', message, filename: filename, span:
        span, throwing: options.throwOnErrors);
  }

  /** [message] is considered a type warning by the Dart lang. */
  void warning(String message, {String filename, SourceSpan span}) {
    if (options.warningsAsErrors) {
      error(message, filename: filename, span: span);
      return;
    }

    warnings++;
    if (options.showWarnings) {
      _message(MAGENTA_COLOR, 'warning: ', message, filename: filename, span:
          span, throwing: options.throwOnWarnings);
    }
  }

  /** [message] at [filename] is so bad we can't generate runnable code. */
  void fatal(String message, {String filename, SourceSpan span}) {
    errors++;
    seenFatal = true;
    _message(RED_COLOR, 'fatal: ', message, filename: filename, span:
        span, throwing: options.throwOnFatal || options.throwOnErrors);
  }

  /**
   * [message] at [filename] will tell the user about what the compiler
   * is doing.
   */
  void info(String message, {String filename, SourceSpan span}) {
    if (options.showInfo) {
      _message(GREEN_COLOR, 'info: ', message, filename: filename,
          span: span, throwing: false);
    }
  }

  bool get hasErrors => errors > 0;

  withTiming(String name, f()) {
    final sw = new Stopwatch();
    sw.start();
    var result = f();
    sw.stop();
    info('$name in ${sw.elapsedInMs()}msec');
    return result;
  }
}
