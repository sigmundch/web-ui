// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('utils');
#import('package:web_components/src/template/world.dart');

/**
 * Converts a string name with hyphens into an identifier, by removing hyphens
 * and capitalizing the following letter.
 */
String toCamelCase(String hyphenedName) {
  var segments = hyphenedName.split('-');
  for (int i = 1; i < segments.length; i++) {
    var segment = segments[i];
    if (segment.length > 0) {
      // Character between 'a'..'z' mapped to 'A'..'Z'
      segments[i] = '${segment[0].toUpperCase()}${segment.substring(1)}';
    }
  }
  return Strings.join(segments, '');
}

/**
 * Invokes [callback], logs how long it took to execute in ms, and returns
 * whatever [callback] returns. The log message will be printed if either
 * [:options.showInfo:] or [printTime] are true.
 */
time(String logMessage, callback(), [bool printTime = false]) {
  final watch = new Stopwatch();
  watch.start();
  var result = callback();
  watch.stop();
  final duration = watch.elapsedInMs();
  if (options.showInfo || printTime) {
    print('$logMessage in $GREEN_COLOR$duration ms$NO_COLOR');
  }
  return result;
}

// Color constants used for generating messages.
final String GREEN_COLOR = '\u001b[32m';
final String RED_COLOR = '\u001b[31m';
final String MAGENTA_COLOR = '\u001b[35m';
final String NO_COLOR = '\u001b[0m';

/** Find and return the first element in [list] that satisfies [matcher]. */
find(List list, bool matcher(elem)) {
  for (var elem in list) {
    if (matcher(elem)) return elem;
  }
  return null;
}
