// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A test configuration that generates a compact 1-line progress bar. The bar is
 * updated in-place before and after each test is executed. If all test pass,
 * you should only see a couple lines in the terminal. If a test fails, the
 * failure is shown and the progress bar continues to be updated below it.
 */
library compact_vm_config;

import 'dart:io';
import 'package:unittest/unittest.dart';

const String _GREEN = '\u001b[32m';
const String _RED = '\u001b[31m';
const String _NONE = '\u001b[0m';

class CompactVMConfiguration extends Configuration {
  Date _start;
  int _pass = 0;
  int _fail = 0;

  void onInit() {
    super.onInit();
  }

  void onStart() {
    super.onStart();
    _start = new Date.now();
  }

  void onTestStart(TestCase test) {
    super.onTestStart(test);
    _progressLine(_start, _pass, _fail, test.description);
  }

  void onTestResult(TestCase test) {
    super.onTestResult(test);
    if (test.result == PASS) {
      _pass++;
      _progressLine(_start, _pass, _fail, test.description);
    } else {
      _fail++;
      _progressLine(_start, _pass, _fail, test.description);
      print('');
      if (test.message != '') {
        print(_indent(test.message));
      }

      if (test.stackTrace != null && test.stackTrace != '') {
        print(_indent(test.stackTrace));
      }
    }
  }

  String _indent(String str) {
    return Strings.join(str.split("\n").map((line) => "  $line"), "\n");
  }

  void onDone(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    var success = false;
    if (passed == 0 && failed == 0 && errors == 0) {
      print('\nNo tests ran.');
    } else if (failed == 0 && errors == 0 && uncaughtError == null) {
      _progressLine(_start, _pass, _fail, 'All tests pass', _GREEN);
      print('\nAll $passed tests passed.');
      success = true;
    } else {
      _progressLine(_start, _pass, _fail, 'Some tests fail', _RED);
      print('');
      if (uncaughtError != null) {
        print('Top-level uncaught error: $uncaughtError');
      }
      print('$passed PASSED, $failed FAILED, $errors ERRORS');
    }

    if (!success) exit(1);
  }

  int _lastLength = 0;

  void _progressLine(Date startTime, int passed, int failed, String message,
      [String color = _NONE]) {
    var duration = (new Date.now()).difference(startTime);
    var buffer = new StringBuffer();
    // \r moves back to the beginnig of the current line.
    buffer.add('\r${_timeString(duration)} ');
    buffer.add(_GREEN);
    buffer.add('+');
    buffer.add(passed);
    buffer.add(_NONE);
    if (failed != 0) buffer.add(_RED);
    buffer.add(' -');
    buffer.add(failed);
    if (failed != 0) buffer.add(_NONE);
    buffer.add(': ');
    buffer.add(color);
    buffer.add(message);
    buffer.add(_NONE);

    // Pad the rest of the line so that it looks erased.
    int len = buffer.length + 1;
    while (buffer.length < _lastLength) {
      buffer.add(' ');
    }
    _lastLength = len;
    stdout.writeString(buffer.toString());
  }

  String _padTime(int time) =>
    (time == 0) ? '00' : ((time < 10) ? '0$time' : '$time');

  String _timeString(Duration duration) {
    var min = duration.inMinutes;
    var sec = duration.inSeconds % 60;
    return '${_padTime(min)}:${_padTime(sec)}';
  }
}

void useCompactVMConfiguration() {
  configure(new CompactVMConfiguration());
}
