// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");
#import("package:args/args.dart");
#import("tools/template/tool.dart", prefix: "templatetool");

bool cleanBuild;
bool fullBuild;
List<String> changedFiles;
List<String> removedFiles;

/**
 * This build script is invoked automatically by the Editor whenever a file
 * in the project changes. It must be placed in the root of a project and named
 * 'build.dart'. The legal command-line parameters are:
 *
 * * <none>: a full build is requested
 * * --clean: remove any build artifacts
 * * --changed=one.foo: the file has changed since the last build
 * * --removed=one.foo: the file has been removed since the last build
 *
 * Any error code other then 0 returned by the script is considered an error.
 * The error, and any stdout or stderr text, will by printed to the console.
 */
void main() {
  print("running build.dart...");
  processArgs();

  if (cleanBuild) {
    handleCleanCommand();
  } else if (fullBuild) {
    handleFullBuild();
  } else {
    handleChangedFiles(changedFiles);
    handleRemovedFiles(removedFiles);
  }
}

/**
 * Handle the -clean and -changed command-line args.
 */
void processArgs() {
  var parser = new ArgParser();
  parser.addOption("changed", help: "the file has changed since the last build",
      allowMultiple: true);
  parser.addOption("removed", help: "the file was removed since the last build",
      allowMultiple: true);
  parser.addFlag("clean", negatable: false, help: "remove any build artifacts");
  parser.addFlag("help", negatable: false, help: "displays this help and exit");
  var args = parser.parse(new Options().arguments);
  if (args["help"]) {
    print(parser.getUsage());
    exit(0);
  }

  changedFiles = args["changed"];
  removedFiles = args["removed"];
  cleanBuild = args["clean"];
  fullBuild = changedFiles.isEmpty() && removedFiles.isEmpty() && !cleanBuild;
}

/**
 * Delete all generated .foobar files.
 */
void handleCleanCommand() {
  Directory current = new Directory.current();
  current.list(true).onFile = _maybeClean;
}

/**
 * Recursively scan the current directory looking for .foo files to process.
 */
void handleFullBuild() {
  var files = <String>[];
  var lister = new Directory.current().list(true);
  lister.onFile = (file) => files.add(file);
  lister.onDone = (_) => handleChangedFiles(files);
}

/**
 * Process the given list of changed files.
 */
void handleChangedFiles(List<String> files) => files.forEach(_processFile);

/**
 * Process the given list of removed files.
 */
void handleRemovedFiles(List<String> files) => files.forEach(_maybeClean);

/**
 * Convert a .foo file to a .foobar file.
 */
void _processFile(String arg) {
  if (arg.endsWith(".tmpl")) {
    print("processing: ${arg}");
    templatetool.run([arg, '$arg.dart']);
  }
}

void _maybeClean(String file) {
  if (file.endsWith(".tmpl.dart")) {
    new File(file).delete();
  }
}
