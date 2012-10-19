// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library errors;

import 'package:html5lib/dom_parsing.dart';
import 'package:logging/logging.dart'
import 'utils.dart';

typedef void PrintHandler(String message);

/** Generates the mapping between error levels and their color. */
Map<Level, String> _errorColorsGenerator() {
  var colorsMap = new Map<Level, String>();
  colorsMap[Level.ERROR] = RED_COLOR;
  colorsMap[Level.WARNING] = MAGENTA_COLOR;
  colorsMap[Level.SEVERE] = RED_COLOR;
  colorsMap[Level.INFO] = GREEN_COLOR;
  return colorsMap;
}

/** Map between error levels and their display color. */
final Map<Level, String> ERROR_COLORS = _errorColorsGenerator();

/** A single error from the compiler. */
class Error {
  final Level level;
  final String message;
  final String filename;
  final SourceSpan span;
  final bool useColors;

  Error(this.level, this.message, {this.filename, this.span,
      this.useColors: false});

  Error.error(this.message, {this.filename, this.span)

  String toString() {
    var output = new StringBuffer();

    output.add(useColors && ERROR_COLORS.containsKey(level) ?
      '${ERROR_COLORS[level]}${level.name}${NO_COLOR}' : '${level.name}');

    output.add(filename != null ? '${filename}: ' : '');
    output.add(message);

    // TODO(jmesserly): Give that span.toMessageString some arguments. Spans
    // love arguments.
    output.add(span != null ? '\n${span.toMessageString}' : '');

    return output.toString();
  }
}

/** An object for holding and printing errors. */
class Errors {
  /** Called on every error. Set to blank function to supress printing. */
  final PrintHandler printHandler;

  final ArgResults options;

  List<Error> errors = new List<Error>();

  Errors({this.printHandler: print, this.options});

  /** [message] is considered a static compile-time error by the Dart lang. */
  void error(String message, {String filename, SourceSpan span}) {
    var error = new Error(Level.ERROR, message, filename: filename, span: span,
        useColors: !options['no_colors']));

    errors.add(error);

    printHandler(error);
  }

  /** [message] is considered a type warning by the Dart lang. */
  void warning(String message, {String filename, SourceSpan span}) {
    if (options['warnings_as_errors']) {
      error(message, filename: filename, span: span);
    } else {
      var error = new Error(Level.WARNING, message, filename: filename,
        span: span, useColors: !options['no_colors']));

      errors.add(error);

      if (!options['supress_warnings']) {
        printHandler(error);
      }
    }
  }

  /** [message] at [filename] is so bad we can't generate runnable code. */
  void fatal(String message, {String filename, SourceSpan span}) {
    var error = new Error(Level.SEVERE, message, filename: filename, span: span,
        useColors: !options['no_colors']));

    errors.add(error);

    printHandler(error);
  }

  /**
   * [message] at [filename] will tell the user about what the compiler
   * is doing.
   */
  void info(String message, {String filename, SourceSpan span}) {
    var error = new Error(Level.INFO, message, filename: filename, span: span,
        useColors: !options['no_colors']));

    errors.add(error);

    if (options['verbose']) {
      printHandler(error);
    }
  }
}
