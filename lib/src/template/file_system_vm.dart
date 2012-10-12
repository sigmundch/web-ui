// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library file_system_vm;

import 'dart:io';
import 'dart:utf';
import 'file_system.dart';

/** File system implementation using the vm api's. */
class VMFileSystem implements FileSystem {

  /** Pending futures for file write requests. */
  List<Future> _pending = <Future>[];

  Future flush() {
    return Futures.wait(_pending).transform((_) {
      // Some new work might be pending that was only queued up after the call
      // to flush so we cannot simply clear the future list.
      _pending = _pending.filter((f) => !f.hasValue);
      return null;
    });
  }

  void writeString(String path, String text) {
    // TODO(jacobr): the following async code mysterously leads to sporadic
    // data corruption in the Dart VM. We need to create a reliable repro and
    // file a bug with the VM team.
    /*
    _pending.add(new File(path).open(FileMode.WRITE).chain(
        (file) => file.writeString(text).chain((_) => file.close())));
    */
    var file = new File(path).openSync(FileMode.WRITE);
    file.writeStringSync(text);
    file.closeSync();
  }

  Future<String> readAll(String filename) {
    return new File(filename).open().chain((file) =>
        file.length().chain((int length) {
      var buffer = new List<int>(length);

      return file.readList(buffer, 0, length).transform((length) {
        file.close();
        // TODO(jmesserly): support all html5 encodings not just UTF8.
        return new String.fromCharCodes(new Utf8Decoder(buffer).decodeRest());
      });
    }));
  }

  void createDirectory(String path, [bool recursive = false]) {
    // TODO(rnystrom): Implement.
    throw 'createDirectory() is not implemented by VMFileSystem yet.';
  }

  void removeDirectory(String path, [bool recursive = false]) {
    // TODO(rnystrom): Implement.
    throw 'removeDirectory() is not implemented by VMFileSystem yet.';
  }
}
