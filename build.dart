// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Build logic for finding .html files and automatically compiling them. */
library build;

import 'dart:io';
import 'package:args/args.dart';
import 'package:web_components/dwc.dart' as dwc;

bool cleanBuild;
bool fullBuild;
bool forceBuild;
List<String> changedFiles;
List<String> removedFiles;

/**
 * This build script is invoked automatically by the Editor whenever a file
 * in the project changes. It must be placed in the root of a project and named
 * 'build.dart'. See the source code of [processArgs] for information about the
 * legal command line options.
 */
void main() {
  processArgs();

  if (!forceBuild) {
    print('build.dart is currently disabled until we have an easy way to \n'
          'ignore and clean output files. You can override this with --force.');
    return;
  }

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
 * Handle the --changed, --removed, --clean and --help command-line args.
 */
void processArgs() {
  var parser = new ArgParser();
  parser.addOption("changed", help: "the file has changed since the last build",
      allowMultiple: true);
  parser.addOption("removed", help: "the file was removed since the last build",
      allowMultiple: true);
  parser.addFlag("clean", negatable: false, help: "remove any build artifacts");
  parser.addFlag("help", negatable: false, help: "displays this help and exit");
  parser.addFlag("force", negatable: false, help: "forces a build");
  var args = parser.parse(new Options().arguments);
  if (args["help"]) {
    print(parser.getUsage());
    exit(0);
  }

  changedFiles = args["changed"];
  removedFiles = args["removed"];
  cleanBuild = args["clean"];
  forceBuild = args["force"];
  fullBuild = changedFiles.isEmpty() && removedFiles.isEmpty() && !cleanBuild;
}

/** Delete all generated files. */
void handleCleanCommand() {
  Directory current = new Directory.current();
  current.list(true).onFile = _maybeClean;
}

/**
 * Recursively scan the current directory looking for template files to process.
 */
void handleFullBuild() {
  var files = <String>[];
  var lister = new Directory.current().list(true);
  lister.onFile = (file) => files.add(file);
  lister.onDone = (_) => handleChangedFiles(files);
}

/** Process the given list of changed files. */
void handleChangedFiles(List<String> files) => files.forEach(_processFile);

/** Process the given list of removed files. */
void handleRemovedFiles(List<String> files) => files.forEach(_maybeClean);

/** Compile .html files with the template tool. */
void _processFile(String filePath) {
  var path = new Path.fromNative(filePath);
  if (path.segments().indexOf('packages') >= 0) {
    // Don't recurse into "packages" symlinks.
    // TODO(jmesserly): ideally we could skip all symlinks.
    return;
  }

  if (path.filename.endsWith(".html") && !path.filename.startsWith("_")) {
    print("processing: $filePath");
    dwc.run([filePath]);
  }
}

/** If this file is a generated file (based on the extension), delete it. */
void _maybeClean(String filePath) {
  // TODO(jmesserly): not sure how to implement this safely.
  // We need to avoid clobbering user's files.
}
