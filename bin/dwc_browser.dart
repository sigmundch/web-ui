// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Compiles Dart Web Components from within a Chrome extension.
 * The Chrome extension logic exists outside of Dart as Dart does not support
 * Chrome extension APIs at this time.
 */
library dwc_browser;

import 'dart:html';
import 'package:args/args.dart';
import 'package:web_components/src/dwc_shared.dart';
import 'package:web_components/src/cmd_options.dart';
import 'package:web_components/src/compiler.dart';
import 'package:web_components/src/file_system.dart';
import 'package:web_components/src/file_system/browser.dart';
import 'package:web_components/src/file_system/path.dart';
import 'package:web_components/src/utils.dart';
import 'package:web_components/src/world.dart';
import 'package:js/js.dart' as js;

FileSystem fileSystem;


void main() {
  js.scoped(() {
    js.context.setOnParseCallback(new js.Callback.many(parse));
  });
}

/**
 * Parse all templates in [sourceFullFn].
 * [sourcePagePort] is a Chrome extension port used to communicate back to the
 * source page that will consume these proxied urls.
 * See extension/background.js.
 */
void parse(js.Proxy sourcePagePort, String sourceFullFn) {
  // TODO(jacobr): we need to send error messages back to sourcePagePort.
  js.retain(sourcePagePort);
  print("Processing: $sourceFullFn");
  // TODO(jacobr): provide a way to pass in options.
  var argParser = commandOptions();
  ArgResults results = argParser.parse([]);

  fileSystem = new BrowserFileSystem(sourcePagePort);

  initHtmlWorld(parseOptions(results, fileSystem));

  Path srcPath = new Path(sourceFullFn);
  Path outputFullDir = srcPath.directoryPath;

  Path srcDir = srcPath.directoryPath;

  String sourceFilename = srcPath.filename;

  asyncTime('Compiled $sourceFullFn', () {
    var compiler = new Compiler(fileSystem);
    return compiler.run(srcPath.filename, srcDir.toString()).chain((_) {
      // Write out the code associated with each source file.
      print("Writing files:");
      for (var file in compiler.output) {
        writeFile(file.filename, outputFullDir, file.contents);
      }
      var ret = fileSystem.flush();
      js.release(sourcePagePort);
      return ret;
    });
  }, printTime: true);
}

void writeFile(String filename, Path outdir, String contents) {
  fileSystem.writeString("${outdir}/$filename", contents);
}
