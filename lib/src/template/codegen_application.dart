// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('codegen_application');

#import('package:html5lib/dom.dart');
#import('package:html5lib/html5parser.dart');

#import('analyzer.dart', prefix: 'analyzer');
#import('code_printer.dart');
#import('codegen.dart');
#import('compile.dart');
#import('source_file.dart');
#import('utils.dart');
#import('world.dart');

/** Support routines to generate Dart code. */
class CodegenApplication {
  static CodegenApplication _cga = const CodegenApplication();

  const CodegenApplication();

  static const String mainMainBody = """
      _componentsSetUp();

      // create view.
      var body = new DocumentFragment.html(INITIAL_PAGE);
      manager.expandDeclarations(body);
  """;

  static const String closeMainMainStartComponentsSetup = """
        // Attach view to the document.
        document.body.nodes.add(body);
      }

      /** Setup components used by application. */
      void _componentsSetUp() {
  """;

  /*
   * [filename] passed in would be filename part (sans '.extension').
   */
  static String generate(Document doc, List<SourceFile> files,
      String libraryName, String filename, ElemCG ecg) {
    // TODO(terry): Validate that the filename matches identifier:
    //              a..z || A..Z || _ [a..z || A..Z || 0..9 || _]*
    if (libraryName.indexOf('.') >= 0) {
      world.fatal("Bad library - $libraryName");
    }

    CodePrinter buff = new CodePrinter();
    buff.add(Codegen.header(filename, libraryName));

    for (var file in files) {
      buff.add("#import('${file.dartFilename}');");
    }

    buff.add(Codegen.commonIncludes);

    if (ecg.includes.length > 0) {
      buff.add("/** Below import from script tag in HTML file. */");
      for (var includeName in ecg.includes) {
        buff.add("#import('$includeName');");
      }
      buff.add("");
    }

    buff.add("/** Create the views and bind them to models. */");
    buff.add("mainMain() {");
    buff.add(mainMainBody);

    // Attach any models.
    buff.add(_cga._emitIterators(ecg));

    buff.add(closeMainMainStartComponentsSetup);

    buff.add(_cga._emitComponentsUsed(files, ecg));

    buff.add("}");

    buff.add("");

    _cga._emitIntialPage(buff, doc);

    return buff.toString();
  }

  static const String DARTJS_LOADER =
    "http://dart.googlecode.com/svn/branches/bleeding_edge/dart/client/dart.js";

  static String generateHTML(Document doc, List<SourceFile> files) {
    var body = doc.queryAll('body');
    assert(body.length == 1);

    // Remove everything in the body; main.html.html should only have the Dart
    // loader script, and MDV bootstrap code.
    var allNodes = body[0].nodes;
    var count = allNodes.length;
    for (var idx = count - 1; idx >= 0; idx--) {
      var node = allNodes[idx];
      // TODO(jmesserly): use tag.remove() once it's supported.
      node.parent.$dom_removeChild(node);
    }

    var newDoc = parse(
        '<script type="text/javascript" src="$DARTJS_LOADER"></script>'
        '<script type="application/dart" src="bootstrap.dart"></script>');

    var scripts = newDoc.queryAll('script');
    for (var script in scripts) {
      // TODO(terry): Should use real appendChild?
      body[0].$dom_appendChild(script as Node);
    }

    // TODO(terry): These link-rel should be removed once we support generating
    //              components(not using the js_polyfill script).
    var linkParent;
    var links = doc.queryAll('link');
    for (var link in links) {
      if (link.attributes["rel"] == "components") {
        if (linkParent == null) {
          linkParent = link.parent;
        }
        link.parent.$dom_removeChild(link);
      }
    }

    // Add all links for any web components used in this application.
    if (linkParent != null) {
      StringBuffer buff = new StringBuffer();
      for (var file in files) {
        buff.add('<link rel="components" href = "${file.htmlFilename}">');
      }

      var linksDoc = parse(buff.toString());
      var newLinks = linksDoc.queryAll("link");
      for (var link in newLinks) {
        linkParent.$dom_appendChild(link as Node);
      }
    }

    return doc.outerHTML;
  }

  String _emitIterators(ElemCG ecg) {
    // Iterate thru any iterate templates being used.
    CodePrinter codePrinter = new CodePrinter(1);

    CGBlock cgb;
    int templateIdx = 1;
    while ((cgb = ecg.templateCG(templateIdx)) != null) {
      cgb.emitTemplateIterate(codePrinter, templateIdx++);
    }

    return codePrinter.toString();
  }

  /** Construct all components use in the main app. */
  String _emitComponentsUsed(List<SourceFile> files, ElemCG ecg) {
    var codePrinter = new CodePrinter(2);
    codePrinter.add("Map<String, Function> map = {");

    // TODO(jmesserly): seems like this should be done in analysis phase.
    var usedComponents = new Set();
    for (var file in files) {
      usedComponents.addAll(file.info.usedComponents);
    }

    for (var file in files) {
      if (usedComponents.contains(file.webComponentName)) {
        codePrinter.add("'${file.webComponentName}': "
            "() => new ${file.elemCG.className}(),");
      }
    }

    codePrinter.add("};");
    codePrinter.add("initializeComponents((name) => map[name]);");
    return codePrinter.toString();
  }

  /** Emits the intial page; everything in the body. */
  void _emitIntialPage(CodePrinter out, Document doc) {
    var body = doc.queryAll('body');
    assert(body.length == 1);

    out.add("final String INITIAL_PAGE = \"\"\"");
    out.add(body[0].innerHTML.trim());
    out.add("\"\"\";");
  }
}
