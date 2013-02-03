// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library console;

import 'dart:async';
import 'dart:io';
import 'dart:utf';
import 'package:web_ui/src/file_system.dart';
import 'path.dart' as internal;

/** File system implementation for console VM (i.e. no browser). */
class ConsoleFileSystem implements FileSystem {

  /** Pending futures for file write requests. */
  Map<String, Future> _pending = <String, Future>{};
  
  Future flush() {
    var pending = _pending;
    return Future.wait(pending.values).then((_) => 
        _pending = <String, Future>{});
  }  
  
  void writeString(internal.Path path, String text) {
    var pathString = path.toString();
    if(!_pending.containsKey(pathString)) {
      var future = new File(pathString).open(FileMode.WRITE).then((file) =>
          file.writeString(text)).then((file) => file.close());
      _pending[pathString] = future;
    }
  }

  // TODO(jmesserly): even better would be to pass the RandomAccessFile directly
  // to html5lib. This will require a further restructuring of FileSystem.
  // Probably it just needs "readHtml" and "readText" methods.
  Future<List<int>> readTextOrBytes(internal.Path path) {
    return new File(path.toString()).open().then(
        (file) => file.length().then((length) {
      // TODO(jmesserly): is this guaranteed to read all of the bytes?
      var buffer = new List<int>(length);
      return file.readList(buffer, 0, length)
          .then((_) => file.close())
          .then((_) => buffer);
    }));
  }

  // TODO(jmesserly): do we support any encoding other than UTF-8 for Dart?
  Future<String> readText(internal.Path path) {
    return readTextOrBytes(path).then(decodeUtf8);
  }
}
