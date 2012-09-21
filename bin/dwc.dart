#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library templatetool;

import 'dart:io';
import 'package:args/args.dart';
import 'package:web_components/src/template/cmd_options.dart';
import 'package:web_components/src/template/file_system.dart';
import 'package:web_components/src/template/file_system_vm.dart';
import 'package:web_components/src/template/world.dart';
import 'package:web_components/src/template/compile.dart';
import 'package:web_components/src/template/template.dart';
import 'package:web_components/src/template/utils.dart';

FileSystem fileSystem;

void main() => run(new Options().arguments);

/** tool.dart [options...] <sourcefile fullpath> <outputfile fullpath> */
void run(List<String> args) {
  var argParser = commandOptions();
  ArgResults results = argParser.parse(args);
  if (results['help'] || results.rest.length == 0) {
    print('Usage: [options...] sourcefile [outputPath]\n');
    print(argParser.getUsage());
    print("   sourcefile - template file filename.html");
    print("   outputPath - if specified directory to generate files; if not");
    print("                same directory as sourcefile");
    return;
  }

  fileSystem = new VMFileSystem();

  initHtmlWorld(parseOptions(results, fileSystem));

  // argument 0 - sourcefile full path
  // argument 1 - output path
  String sourceFullFn = results.rest[0];
  String outputFullDir = results.rest.length > 1 ? results.rest[1] : null;

  Path srcPath = new Path(sourceFullFn);

  Directory srcDir = new Directory.fromPath(srcPath.directoryPath);
  if (!srcDir.existsSync()) {
    world.fatal("Input directory doesn't exist - ${srcDir.path}");
    return;
  }

  File fileSrc = new File.fromPath(srcPath);
  if (!fileSrc.existsSync()) {
    world.fatal("Source file doesn't exist - ${fileSrc.name}");
    return;
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

  String source = fileSystem.readAll(sourceFullFn);
  time('Compiled $sourceFullFn', () {
    var compiler = new Compile(fileSystem);
    compiler.run(srcPath.filename, srcDir.path);

    // Write out the code associated with each source file.
    print("Write files to ${outDirectory.path}:");
    for (var file in compiler.files) {
      var info = compiler.info[file];
      writeFile(info.dartFilename, outDirectory, info.generatedCode);
      writeFile(info.htmlFilename, outDirectory, info.generatedHtml);
    }
  }, printTime: true);
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
