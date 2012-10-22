// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The entry point to the compiler. Used to implement `bin/dwc.dart`. */
library dwc;

import 'src/file_system.dart';
import 'src/file_system/console.dart';
import 'src/compiler.dart';
import 'src/messages.dart';
import 'src/options.dart';
import 'src/utils.dart';
import 'dart:io';

FileSystem fileSystem;

// TODO(jmesserly): fix this to return a proper exit code
/** bin/dwc.dart [options...] <sourcefile fullpath> <outputfile fullpath> */
Future run(List<String> args) {
  var options = CompilerOptions.parse(args);
  if (options == null) return new Future.immediate(null);

  fileSystem = new ConsoleFileSystem();
  messages = new Messages(options: options);

  // argument 0 - sourcefile full path
  // argument 1 - output path
  String sourceFullFn = options.rest[0];
  String outputFullDir = options.rest.length > 1 ? options.rest[1] : null;

  Path srcPath = new Path(sourceFullFn);

  Path srcDirPath = srcPath.directoryPath;
  Directory srcDir = srcDirPath.isEmpty
      ? new Directory.current() : new Directory.fromPath(srcDirPath);
  if (!srcDir.existsSync()) {
    messages.error("Input directory doesn't exist", null,
        filename: srcDir.path);
    return new Future.immediate(null);
  }

  File fileSrc = new File.fromPath(srcPath);
  if (!fileSrc.existsSync()) {
    messages.error("Source file doesn't exist.", null, filename: fileSrc.name);
    return new Future.immediate(null);
  }

  if (!fileSrc.name.endsWith('.html')) {
    messages.error("Source file is not an html file.", null,
        filename: fileSrc.name);
    return new Future.immediate(null);
  }

  String sourceFilename = fileSrc.name;

  // If outputFullDirectory not specified use the directory of the source file.
  if (outputFullDir == null || outputFullDir.isEmpty()) {
    outputFullDir = srcDir.path;
  }

  Directory outDirectory = new Directory(outputFullDir);
  if (!outDirectory.existsSync()) {
    outDirectory.createSync();
  }

  return asyncTime('Compiled $sourceFullFn', () {
    var compiler = new Compiler(fileSystem, options);
    return compiler.run(srcPath.filename, srcDir.path).chain((_) {
      // Write out the code associated with each source file.
      print("Write files to ${outDirectory.path}:");
      for (var file in compiler.output) {
        writeFile(file.filename, outDirectory, file.contents, options.clean);
      }
      return fileSystem.flush();
    });
  }, printTime: true);
}

void writeFile(String filename, Directory outdir, String contents, bool clean) {
  String path = "${outdir.path}/$filename";
  if (clean) {
    File fileOut = new File.fromPath(new Path(path));
    if (fileOut.existsSync()) {
      fileOut.deleteSync();
      print("  Deleting $filename");
    }
  } else {
    fileSystem.writeString(path, contents);
    print("  Writing $filename");
  }
}
