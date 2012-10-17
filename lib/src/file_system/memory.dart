// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(terry): Investigate common library for file I/O shared between frog and tools.

library memory;

import 'package:web_components/src/file_system.dart';

/**
 * [FileSystem] implementation a memory buffer.
 */
class MemoryFileSystem implements FileSystem {
  StringBuffer buffer = new StringBuffer();

  MemoryFileSystem();

  Future flush() {
    return new Future.immediate(null);
  }

  void writeString(String outfile, String text) {
    buffer.add(text);
  }

  Future<String> readAll(String filename) {
    return new Future<String>.immediate(buffer.toString());
  }

  void createDirectory(String path, [bool recursive]) {
    // TODO(terry): To be implement.
    throw 'createDirectory() is not implemented by MemoryFileSystem yet.';
  }

  void removeDirectory(String path, [bool recursive]) {
    // TODO(terry): To be implement.
    throw 'removeDirectory() is not implemented by MemoryFileSystem yet.';
  }
}
