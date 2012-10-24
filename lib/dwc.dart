// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The entry point to the compiler. Used to implement `bin/dwc.dart`. */
library dwc;

import 'src/compiler.dart';
import 'src/file_system.dart';
import 'src/file_system/console.dart';
import 'src/file_system/path.dart' as fs;
import 'src/messages.dart';
import 'src/options.dart';
import 'src/utils.dart';
import 'dart:io';

FileSystem fileSystem;

void main() {
  run(new Options().arguments);
}

// TODO(jmesserly): fix this to return a proper exit code
/** bin/dwc.dart [options...] <sourcefile fullpath> <outputfile fullpath> */
Future run(List<String> args) {
  var options = CompilerOptions.parse(args);
  if (options == null) return new Future.immediate(null);

  fileSystem = new ConsoleFileSystem();
  messages = new Messages(options: options);

  var inputFile = options.rest[0];
  var outputDir = options.rest.length > 1 ? options.rest[1] : null;

  var currentDir = new Directory.current().path;

  var srcPath = new Path(inputFile);
  if (srcPath.isAbsolute && inputFile.startsWith(currentDir)) {
    inputFile = inputFile.substring(currentDir.length + 1);
    srcPath = new Path(inputFile);
  }

  var srcDirPath = srcPath.directoryPath;
  var srcDir = srcDirPath.isEmpty
      ? new Directory.current() : new Directory.fromPath(srcDirPath);
  if (!srcDir.existsSync()) {
    messages.error("Input directory doesn't exist", null,
        file: new fs.Path(srcDir.path));
    return new Future.immediate(null);
  }

  var fileSrc = new File.fromPath(srcPath);
  if (!fileSrc.existsSync()) {
    messages.error("Source file doesn't exist.", null,
        file: new fs.Path(inputFile));
    return new Future.immediate(null);
  }

  if (!fileSrc.name.endsWith('.html')) {
    messages.error("Source file is not an html file.", null,
        file: new fs.Path(inputFile));
    return new Future.immediate(null);
  }

  // If outputFullDirectory not specified use the directory of the source file.
  if (outputDir == null || outputDir.isEmpty) {
    outputDir = srcDir.path;
  }

  return asyncTime('Compiled $srcPath', () {
    var compiler = new Compiler(fileSystem, options);
    return compiler.run(inputFile, outputDir).chain((_) {
      // Write out the code associated with each source file.
      print("Write files to $outputDir:");
      for (var file in compiler.output) {
        writeFile(file.path, file.contents, options.clean);
      }
      return fileSystem.flush();
    });
  }, printTime: true);
}

void writeFile(fs.Path path, String contents, bool clean) {
  if (clean) {
    File fileOut = new File.fromPath(_convert(path));
    if (fileOut.existsSync()) {
      fileOut.deleteSync();
    }
  } else {
    _createIfNeeded(_convert(path.directoryPath));
    fileSystem.writeString(path, contents);
  }
}

void _createIfNeeded(Path outdir) {
  if (outdir.isEmpty) return;
  var outDirectory = new Directory.fromPath(outdir);
  if (!outDirectory.existsSync()) {
    _createIfNeeded(outdir.directoryPath);
    outDirectory.createSync();
  }
}

// TODO(sigmund): this conversion from dart:io paths to internal paths should
// go away when dartbug.com/5818 is fixed.
Path _convert(fs.Path path) => new Path(path.toString());
