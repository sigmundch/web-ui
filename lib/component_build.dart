// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Common logic to make it easy to create a `build.dart` for your project.
 *
 * The `build.dart` script is invoked automatically by the Editor whenever a
 * file in the project changes. It must be placed in the root of a project
 * (where pubspec.yaml lives) and should be named exactly 'build.dart'.
 *
 * A common `build.dart` would look as follows:
 *
 *     import 'dart:io';
 *     import 'package:web_components/component_build.dart';
 *
 *     main() => build(new Options().arguments, ['web/main.html']);
 *
 * 
 */
library build_utils;

import 'dart:io';
import 'package:args/args.dart';
import 'package:web_components/dwc.dart' as dwc;

bool _cleanBuild;
bool _fullBuild;
List<String> _changedFiles;
List<String> _removedFiles;
List<String> _entryPoints = [];
List<String> _trackDirs = [];

/**
 * Set up 'build.dart' to compile with the dart web components compiler every
 * [entryPoints] listed. On clean commands, the directory where [entryPoints]
 * live will be scanned for generated files to delete them.
 */
// TODO(jmesserly): we need a better way to automatically detect input files
void build(List<String> args, List<String> entryPoints) {
  _processArgs(args);
  _entryPoints.addAll(entryPoints);
  for (var file in entryPoints) {
    var dir = new Path(file).directoryPath.toString();
    _trackDirs.add((dir != '') ? new Directory(dir) : new Directory.current());
  }

  if (_cleanBuild) {
    _handleCleanCommand();
  } else if (_fullBuild || _changedFiles.some(_isInputFile)
      || _removedFiles.some(_isInputFile)) {
    for (var file in _entryPoints) {
      dwc.run([file]);
    }
  }
}

bool _isGeneratedFile(String filePath) {
  return new Path.fromNative(filePath).filename.startsWith('_');
}

bool _isInputFile(String path) {
  return (path.endsWith(".dart") || path.endsWith(".html"))
      && !_isGeneratedFile(path);
}

/** Delete all generated files. */
void _handleCleanCommand() {
  for (var dir in _trackDirs) {
    dir.list(false).onFile = (path) {
      if (_isGeneratedFile(path)) {
        // TODO(jmesserly): we need a cleaner way to do this with dart:io.
        // The bug is that DirectoryLister returns native paths, so you need to
        // use Path.fromNative to work around this. Ideally we could just write:
        //    new File(path).delete();
        new File.fromPath(new Path.fromNative(path)).delete();
      }
    };
  }
}

/** Handle --changed, --removed, --clean and --help command-line args. */
void _processArgs(List<String> arguments) {
  var parser = new ArgParser()
    ..addOption("changed", help: "the file has changed since the last build",
        allowMultiple: true)
    ..addOption("removed", help: "the file was removed since the last build",
        allowMultiple: true)
    ..addFlag("clean", negatable: false, help: "remove any build artifacts")
    ..addFlag("help", negatable: false, help: "displays this help and exit");
  var args = parser.parse(arguments);
  if (args["help"]) {
    print(parser.getUsage());
    exit(0);
  }

  _changedFiles = args["changed"];
  _removedFiles = args["removed"];
  _cleanBuild = args["clean"];
  _fullBuild = _changedFiles.isEmpty() && _removedFiles.isEmpty()
      && !_cleanBuild;
}
