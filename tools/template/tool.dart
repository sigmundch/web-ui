// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('templatetool');

#import('package:args/args.dart');
#import('dart:io');

#import('package:web_components/tools/lib/cmd_options.dart');
#import('package:web_components/tools/lib/file_system.dart');
#import('package:web_components/tools/lib/file_system_vm.dart');
#import('package:web_components/tools/lib/source.dart');
#import('package:web_components/tools/lib/world.dart');
#import('compile.dart');
#import('compilation_unit.dart');
#import('codegen_application.dart');
#import('template.dart');
#import('utils.dart');

FileSystem files;

void main() => run(new Options().arguments);

/** tool.dart [options...] <sourcefile fullpath> <outputfile fullpath> */
void run(List<String> args) {
  var argParser = commandOptions();
  ArgResults results = argParser.parse(args);
  if (results['help']) {
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
    final compileElapsed = time(() {
      var analyze = new Compile(files, srcPath.filename, srcDir.path);
      // Write out the results.
      print("Write files to ${outDirectory.path}:");

      String outDirPath = outDirectory.path;
      // Write out the code associated with each compilation unit.
      analyze.forEach((CompilationUnit cu) {
        if (!cu.opened || !cu.codeGenerated || !cu.htmlGenerated) {
          world.error(
              "Unexpected compiler error CU ${cu.filename} not processed.");
        } else {
          // Source filename associated with this compilation unit.
          String filename = cu.filename;

          // Output .dart file.
          String dartFilename = cu.dartFilename;
          String dartFilenameFullQual = "$outDirPath/$dartFilename";
          if (options.clean) {
            File fileOut = new File.fromPath(new Path(dartFilenameFullQual));
            if (fileOut.existsSync()) {
              fileOut.deleteSync();
              print("  Deleting $dartFilename");
            }
          } else {
            files.writeString(dartFilenameFullQual, cu.code);
            print("  Writing $dartFilename");
          }

          // Otuput the .html file.
          String htmlFilename = cu.htmlFilename;
          String htmlFilenameFullQual = "$outDirPath/$htmlFilename";
          if (options.clean) {
            File fileOut = new File.fromPath(new Path(htmlFilenameFullQual));
            if (fileOut.existsSync()) {
              fileOut.deleteSync();
              print("  Deleting $htmlFilename");
            }
          } else {
            files.writeString(htmlFilenameFullQual, cu.html);
            print("  Writing $htmlFilename");
          }
        }
      });
    });

    printStats("Compiled", compileElapsed, sourceFullFn);
  }
}
