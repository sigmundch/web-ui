// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library messages;

import 'package:html5lib/dom_parsing.dart';
import 'package:logging/logging.dart';
import 'options.dart';
import 'utils.dart';

// TODO(jmesserly): remove the global messages. We instead use some
// object that tracks compilation state.

/** The global [Messages] for tracking info/warnings/messages. */
Messages messages;

/** Map between error levels and their display color. */
final Map<Level, String> _ERROR_COLORS = (() {
  // TODO(jmesserly): the SourceSpan printer does not use our colors.
  var colorsMap = new Map<Level, String>();
  colorsMap[Level.ERROR] = RED_COLOR;
  colorsMap[Level.WARNING] = MAGENTA_COLOR;
  colorsMap[Level.INFO] = GREEN_COLOR;
  return colorsMap;
})();

/** A single message from the compiler. */
class Message {
  final Level level;
  final String message;
  final String filename;
  final SourceSpan span;
  final bool useColors;

  Message(this.level, this.message, {this.filename, this.span,
      this.useColors: false});

  String toString() {
    var output = new StringBuffer();
    bool colors = useColors && _ERROR_COLORS.containsKey(level);
    if (colors) output.add(_ERROR_COLORS[level]);
    output.add(level.name);
    if (colors) output.add(NO_COLOR);

    if (span == null) {
      if (filename != null) output.add('$filename: ');
      output.add(message);
    } else {
      output.add(span.toMessageString(filename, message, useColors: colors));
    }

    return output.toString();
  }
}

typedef void PrintHandler(Object obj);

/**
 * This class tracks and prints information, warnings, and errors emitted by the
 * compiler.
 */
class Messages {
  /** Called on every error. Set to blank function to supress printing. */
  final PrintHandler printHandler;

  final CompilerOptions options;

  final List<Message> messages = <Message>[];

  Messages({CompilerOptions options, this.printHandler: print})
      : options = options != null ? options : new CompilerOptions();

  /** [message] is considered a static compile-time error by the Dart lang. */
  void error(String message, {String filename, SourceSpan span}) {
    var msg = new Message(Level.SEVERE, message, filename: filename, span: span,
        useColors: options.useColors);

    messages.add(msg);

    printHandler(msg);
  }

  /** [message] is considered a type warning by the Dart lang. */
  void warning(String message, {String filename, SourceSpan span}) {
    if (options.warningsAsErrors) {
      error(message, filename: filename, span: span);
    } else {
      var msg = new Message(Level.WARNING, message, filename: filename,
        span: span, useColors: options.useColors);

      messages.add(msg);
    }
  }

  /**
   * [message] at [filename] will tell the user about what the compiler
   * is doing.
   */
  void info(String message, {String filename, SourceSpan span}) {
    var msg = new Message(Level.INFO, message, filename: filename, span: span,
        useColors: options.useColors);

    messages.add(msg);

    if (options.verbose) printHandler(msg);
  }
}
