// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The entry point to the compiler. Used to implement `bin/dwc.dart`. */
library dwc;

import 'package:args/args.dart';
import 'src/template/cmd_options.dart';
import 'src/template/file_system.dart';
import 'src/template/file_system_vm.dart';
import 'src/template/file_system_memory.dart';
import 'src/template/compile.dart';
import 'src/template/utils.dart';
import 'src/template/world.dart';
import 'dwc_shared.dart';
import 'dart:io';

FileSystem fileSystem;

/** bin/dwc.dart [options...] <sourcefile fullpath> <outputfile fullpath> */
Future run(List<String> args) {
  var argParser = commandOptions();
  ArgResults results = argParser.parse(args);
  if (results['help'] || results.rest.length == 0) {
    print('Usage: [options...] sourcefile [outputPath]\n');
    print(argParser.getUsage());
    print("   sourcefile - template file filename.html");
    print("   outputPath - if specified directory to generate files; if not");
    print("                same directory as sourcefile");
    return new Future.immediate(null);
  }

  fileSystem = new VMFileSystem();

  initHtmlWorld(parseOptions(results, fileSystem));

  // argument 0 - sourcefile full path
  // argument 1 - output path
  String sourceFullFn = results.rest[0];
  String outputFullDir = results.rest.length > 1 ? results.rest[1] : null;

  Path srcPath = new Path(sourceFullFn);

  Path srcDirPath = srcPath.directoryPath;
  Directory srcDir = srcDirPath.isEmpty
      ? new Directory.current() : new Directory.fromPath(srcDirPath);
  if (!srcDir.existsSync()) {
    world.fatal("Input directory doesn't exist - ${srcDir.path}");
    return new Future.immediate(null);
  }

  File fileSrc = new File.fromPath(srcPath);
  if (!fileSrc.existsSync()) {
    world.fatal("Source file doesn't exist.", filename: fileSrc.name);
    return new Future.immediate(null);
  }

  if (!fileSrc.name.endsWith('.html')) {
    world.fatal("Source file is not an html file.", filename: fileSrc.name);
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

  return fileSystem.readAll(sourceFullFn).chain((source) {
    return asyncTime('Compiled $sourceFullFn', () {
      var compiler = new Compile(fileSystem);
      return compiler.run(srcPath.filename, srcDir.path).chain((_) {
        // Write out the code associated with each source file.
        print("Write files to ${outDirectory.path}:");
        for (var file in compiler.output) {
          writeFile(file.filename, outDirectory, file.contents);
        }
        return fileSystem.flush();
      });
    }, printTime: true);
  });
}

void writeFile(String filename, Directory outdir, String contents) {
  String path = "${outdir.path}/$filename";
  if (options.clean) {
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
