// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tools to help implement refactoring like transformations to Dart code.
 *
 * [TextEditTransaction] supports making a series of changes to a text buffer.
 * [guessIndent] helps to guess the appropriate indentiation for the new code.
 */
library refactor;

const $CR = 13;
const $LF = 10;
const $TAB = 9;
const $SPACE = 32;

/**
 * Editable text transaction. Applies a series of edits using original location
 * information, and composes them into the edited string.
 */
class TextEditTransaction {
  final String original;
  final _edits = <_TextEdit>[];

  TextEditTransaction(this.original);

  bool get hasEdits => _edits.length > 0;

  /**
   * Edit the original text, replacing text on the range [begin] and [end]
   * with the [replace] text.
   */
  void edit(int begin, int end, String replace) {
    _edits.add(new _TextEdit(begin, end, replace));
  }

  /**
   * Applies all pending [edit]s and returns the rewritten string.
   * If no edits were made, returns the [original] string.
   * Throws [UnsupportedError] if the edits were overlapping.
   */
  String commit() {
    if (_edits.length == 0) return original;

    // Sort edits by start location.
    _edits.sort((x, y) => x.begin - y.begin);

    var result = new StringBuffer();
    int consumed = 0;
    for (var edit in _edits) {
      if (consumed > edit.begin) {
        throw new UnsupportedError('overlapping edits: insert at offset '
          '${edit.begin} but have consumed $consumed input characters.');
      }

      // Add characters from the original string between this edit and the last
      // one, if any.
      var betweenEdits = original.substring(consumed, edit.begin);
      result..add(betweenEdits)..add(edit.replace);
      consumed = edit.end;
    }

    // Add any text from the end of the original string that was not replaced.
    result.add(original.substring(consumed));
    return result.toString();
  }
}

class _TextEdit {
  final int begin;
  final int end;
  final String replace;

  _TextEdit(this.begin, this.end, this.replace);

  int get length => end - begin;
}

/**
 * Finds and returns all whitespace characters at the start of the current line.
 */
String guessIndent(String code, int charOffset) {
  // Find the beginning of the line
  int lineStart = 0;
  for (int i = charOffset - 1; i >= 0; i--) {
    var c = code.charCodeAt(i);
    if (c == $LF || c == $CR) {
      lineStart = i + 1;
      break;
    }
  }

  // Grab all the whitespace
  int whitespaceEnd = code.length;
  for (int i = lineStart; i < code.length; i++) {
    var c = code.charCodeAt(i);
    if (c != $SPACE && c != $TAB) {
      whitespaceEnd = i;
      break;
    }
  }

  return code.substring(lineStart, whitespaceEnd);
}
