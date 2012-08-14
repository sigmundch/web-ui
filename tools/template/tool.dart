// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('templatetool');

#import('dart:io');
#import('package:args/args.dart');

#import('../lib/cmd_options.dart');
#import('../lib/file_system.dart');
#import('../lib/file_system_vm.dart');
#import('../lib/source.dart');
#import('../lib/world.dart');
#import('codegen.dart');
#import('htmltree.dart');
#import('template.dart');

FileSystem files;

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

printStats(String phase, num elapsed, [String filename = '']) {
  print('${phase} ${GREEN_COLOR}${filename}${NO_COLOR} in ${elapsed} msec.');
}

/**
 * Run from the `utils/css` directory.
 */
void main() {
  // tool.dart [options...] <sourcefile fullpath> <outputfile fullpath>
  var args = commandOptions();
  ArgResults results = args.parse(new Options().arguments);

  if (results['help']) {
    print('Usage: [options...] sourcefile outputfile\n');
    print(args.getUsage());
    print("       sourcefile - template file filename.tmpl");
    print("       outputfile - generated dart source file filename.dart");
    return;
  }

  // argument 0 - sourcefile full path
  // argument 1 - outputfile full path
  String sourceFullFn = results.rest[0];
  String outputFullFn = results.rest[1];

  File fileSrc = new File(sourceFullFn);

  if (!fileSrc.existsSync()) {
    world.fatal("Source file doesn't exist - sourceFullFn");
  }

  Directory sourcePath = fileSrc.directorySync();
  String sourceFilename = fileSrc.name;

  Path outPath = new Path(outputFullFn);

  // The createSync is required to ensure that the directory is fully qualified
  // using the current working directory.
  File fileOut = new File.fromPath(outPath);
  fileOut.createSync();
  Directory outDir = fileOut.directorySync();
  if (!outDir.existsSync()) {
    world.fatal("Output directory doesn't exist - $outDir");
  }

  String outFileNameNoExt =
      outPath.filenameWithoutExtension.replaceAll('.', '_');

  files = new VMFileSystem();

  // TODO(terry): Cleanup options handling need common options between template
  //              and CSS parsers also cleanup above cruft.

  // TODO(terry): Pass on switches.
  initHtmlWorld(parseOptions(results, files));

  if (!files.fileExists(sourceFullFn)) {
    // Display colored error message if file is missing.
    world.fatal("CSS source file missing - ${sourceFullFn}");
  } else {

    String source = files.readAll(sourceFullFn);

    HTMLDocument tmplDoc;
    final parsedElapsed = time(() {
      tmplDoc = templateParseAndValidate(source);
    });

    StringBuffer code = new StringBuffer();

    num codegenElapsed;
    if (world.errors == 0) {
      // Generate the Dart class(es) for all template(s).
      codegenElapsed = time(() {
        code.add(Codegen.generate(tmplDoc, outFileNameNoExt));
      });
    }

    printStats("Parsed", parsedElapsed, sourceFullFn);
    printStats("Codegen", codegenElapsed, sourceFullFn);

    final outputElapsed = time(() {
      files.writeString(outputFullFn, code.toString());
    });

    printStats("Wrote file", codegenElapsed, outputFullFn);
  }
}
