#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('templatetool');

#import('dart:io');
#import('package:args/args.dart');
#import('package:web_components/src/template/cmd_options.dart');
#import('package:web_components/src/template/file_system.dart');
#import('package:web_components/src/template/file_system_vm.dart');
#import('package:web_components/src/template/world.dart');
#import('package:web_components/src/template/compile.dart');
#import('package:web_components/src/template/template.dart');
#import('package:web_components/src/template/utils.dart');

FileSystem files;

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
    return;
  }

  files = new VMFileSystem();

  // TODO(terry): Cleanup options handling need common options between template
  //              and CSS parsers also cleanup above cruft.

  // TODO(terry): Pass on switches.
  initHtmlWorld(parseOptions(results, files));

  // argument 0 - sourcefile full path
  // argument 1 - output path
  String sourceFullFn = results.rest[0];
  String outputDirectory = results.rest.length > 1 ? results.rest[1] : null;

  File fileSrc = new File(sourceFullFn);

  if (!fileSrc.existsSync()) {
    world.fatal("Source file doesn't exist - $sourceFullFn");
  }

  Directory sourcePath = fileSrc.directorySync();
  String sourceFilename = fileSrc.name;

  Path srcPath = new Path(sourceFullFn);
  // The createSync is required to ensure that the directory is fully qualified
  // using the current working directory.
  File fileIn = new File.fromPath(srcPath);
  fileIn.createSync();
  Directory srcDir = fileIn.directorySync();
  if (!srcDir.existsSync()) {
    world.fatal("Input directory doesn't exist - srcDir");
  }

  // If not outputDirectory not specified use the directory of the source file.
  if (outputDirectory == null || outputDirectory.isEmpty()) {
    outputDirectory = srcDir.path;
  }

  // The createSync is required to ensure that the directory is fully qualified
  // using the current working directory.
  Directory outDirectory = new Directory(outputDirectory);
  if (!outDirectory.existsSync()) {
    world.fatal("Output directory doesn't exist - ${outDirectory.path}");
  }

  if (!files.fileExists(sourceFullFn)) {
    // Display colored error message if file is missing.
    world.fatal("CSS source file missing - ${sourceFullFn}");
  } else {
    String source = files.readAll(sourceFullFn);
    time('Compiled $sourceFullFn', () {
      var compiler = new Compile(files, srcPath.filename, srcDir.path);

      // Write out the code associated with each source file.
      print("Write files to ${outDirectory.path}:");
      for (var file in compiler.files) {
        writeFile(file.dartFilename, outDirectory, file.code);
        writeFile(file.htmlFilename, outDirectory, file.html);
      }
    }, printTime: true);
  }
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
    files.writeString(path, contents);
    print("  Writing $filename");
  }
}
