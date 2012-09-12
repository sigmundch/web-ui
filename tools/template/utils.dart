// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('template_utils');

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

/** Invokes [callback] and returns how long it took to execute in ms. */
num time(callback()) {
  final watch = new Stopwatch();
  watch.start();
  callback();
  watch.stop();
  return watch.elapsedInMs();
}

String GREEN_COLOR = '\u001b[32m';
String NO_COLOR = '\u001b[0m';

prettyStats(String phase, num elapsed, [String filename = '']) {
  print('$phase $GREEN_COLOR$filename$NO_COLOR in $elapsed msec.');
}

printStats(String phase, num elapsed, [String filename = '']) {
  print('$phase $filename in $elapsed msec.');
}

find(List list, bool matcher(elem)) {
  for (var elem in list) {
    if (matcher(elem)) return elem;
  }
  return null;
}
