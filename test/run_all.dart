// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is a helper for run.sh. We try to run all of the Dart code in one
 * instance of the Dart VM to reduce warm-up time.
 */
library run_impl;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show min;
import 'dart:utf' show encodeUtf8;
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'package:web_ui/dwc.dart' as dwc;

import 'analyzer_test.dart' as analyzer_test;
import 'compiler_test.dart' as compiler_test;
import 'emitter_test.dart' as emitter_test;
import 'html5_utils_test.dart' as html5_utils_test;
import 'html_cleaner_test.dart' as html_cleaner_test;
import 'linked_list_test.dart' as linked_list_test;
import 'observe_test.dart' as observe_test;
import 'path_info_test.dart' as path_info_test;
import 'utils_test.dart' as utils_test;
import 'watcher_test.dart' as watcher_test;

main() {
  var args = new Options().arguments;
  var pattern = new RegExp(args.length > 0 ? args[0] : '.');

  useCompactVMConfiguration();

  void addGroup(testFile, testMain) {
    if (pattern.hasMatch(testFile)) {
      group(testFile.replaceAll('_test.dart', ':'), testMain);
    }
  }

  addGroup('analyzer_test.dart', analyzer_test.main);
  addGroup('compiler_test.dart', compiler_test.main);
  addGroup('emitter_test.dart', emitter_test.main);
  addGroup('html5_utils_test.dart', html5_utils_test.main);
  addGroup('html_cleaner_test.dart', html_cleaner_test.main);
  addGroup('linked_list_test.dart', linked_list_test.main);
  addGroup('observe_test.dart', observe_test.main);
  addGroup('path_info_test.dart', path_info_test.main);
  addGroup('utils_test.dart', utils_test.main);
  addGroup('watcher_test.dart', watcher_test.main);

  var paths = new Directory.fromPath(new Path('data/input')).listSync()
      .where((f) => f is File).map((f) => f.name)
      .where((p) => p.endsWith('_test.html') && pattern.hasMatch(p));
  var cwd = new Path(new Directory.current().path);
  for (var path in paths) {
    var filename = new Path(path).filename;
    test('drt-compile $filename', () {
      expect(dwc.run(['-o', 'data/output/', path], printTime: false)
        .then((res) {
          expect(res.messages.length, 0, reason: res.messages.join('\n'));
        }), completes);
    });
  }

  test('drt-run', () {
    var outDir = cwd.append('data').append('output');
    var expectedDir = cwd.append('data').append('expected');
    var filenames = paths.map((p) => new Path(p).filename).toList();
    var inputPaths = filenames.map((n) => '${outDir.append(n)}').toList();
    var outPaths = inputPaths.map((t) => '$t.txt').toList();
    var expectedPaths = filenames
        .map((n) => '${expectedDir.append(n)}.txt').toList();

    expect(Process.run('DumpRenderTree', inputPaths).then((res) {
      expect(res.exitCode, 0, reason: 'DumpRenderTree exit code: $res.exitCode.'
        ' Contents of stderr: \n${res.stderr}');
      var outs = res.stdout.split('#EOF\n#EOF\n');
      expect(outs.length, outPaths.length + 1);
      expect(outs[outs.length - 1], isEmpty);

      // Write out all outputs before we start comparing them.
      for (int i = 0; i < outs.length - 1; i++) {
        new File(outPaths[i]).writeAsStringSync(outs[i]);
      }

      for (int i = 0; i < outs.length - 1; i++) {
        var expected = new File(expectedPaths[i]).readAsStringSync();
        expect(expected, new SmartStringMatcher(outs[i]),
            reason: 'unexpected output for ${filenames[i]}');
      }
    }), completes);
  });
}

// TODO(sigmund): consider moving this matcher to unittest
class SmartStringMatcher extends BaseMatcher {
  final String _value;

  SmartStringMatcher(this._value);

  bool matches(item, MatchState mismatchState) => _value == item;

  Description describe(Description description) =>
      description.addDescriptionOf(_value);

  Description describeMismatch(item, Description mismatchDescription,
      MatchState matchState, bool verbose) {
    if (item is! String) {
      return mismatchDescription.addDescriptionOf(item).add(' not a string');
    } else {
      var buff = new StringBuffer();
      buff.write('Strings are not equal.');
      var escapedItem = _escape(item);
      var escapedValue = _escape(_value);
      int minLength = min(escapedItem.length, escapedValue.length);
      int start;
      for (start = 0; start < minLength; start++) {
        if (escapedValue.codeUnitAt(start) != escapedItem.codeUnitAt(start)) {
          break;
        }
      }
      if (start == minLength) {
        if (escapedValue.length < escapedItem.length) {
          buff.write(' Both strings start the same, but the given value also'
              ' has the following trailing characters: ');
          _writeTrailing(buff, escapedItem, escapedValue.length);
        } else {
          buff.write(' Both strings start the same, but the given value is'
              ' missing the following trailing characters: ');
          _writeTrailing(buff, escapedValue, escapedItem.length);
        }
      } else {
        buff.write('\nExpected: ');
        _writeLeading(buff, escapedValue, start);
        buff.write('[32m');
        buff.write(escapedValue[start]);
        buff.write('[0m');
        _writeTrailing(buff, escapedValue, start + 1);
        buff.write('\n But was: ');
        _writeLeading(buff, escapedItem, start);
        buff.write('[31m');
        buff.write(escapedItem[start]);
        buff.write('[0m');
        _writeTrailing(buff, escapedItem, start + 1);
        buff.write('[32;1m');
        buff.write('\n          ');
        for (int i = (start > 10 ? 14 : start); i > 0; i--) buff.write(' ');
        buff.write('^  [0m');
      }

      return mismatchDescription.replace(buff.toString());
    }
  }

  static String _escape(String s) =>
      s.replaceAll('\n', '\\n').replaceAll('\r', '\\r').replaceAll('\t', '\\t');

  static String _writeLeading(StringBuffer buff, String s, int start) {
    if (start > 10) {
      buff.write('... ');
      buff.write(s.substring(start - 10, start));
    } else {
      buff.write(s.substring(0, start));
    }
  }

  static String _writeTrailing(StringBuffer buff, String s, int start) {
    if (start + 10 > s.length) {
      buff.write(s.substring(start));
    } else {
      buff.write(s.substring(start, start + 10));
      buff.write(' ...');
    }
  }

}
