#library('codegen');

#import('dart:coreimpl');
#import('package:web_components/tools/lib/world.dart');
#import('compile.dart');
#import('utils.dart');

class Codegen {
  static final String SPACES = "                                              ";
  static String spaces(int numSpaces) {
    return SPACES.substring(0, numSpaces);
  }

  static String header(String filename, String libraryName) => """
// Generated Dart class from HTML template $filename.
// DO NOT EDIT.

#library('${libraryName}');

#import('dart:html');
""";

  static String get commonComponents => """
#import('package:web_components/lib/js_polyfill/if.html.dart');
#import('package:web_components/lib/js_polyfill/list.html.dart');
""";

  static String get commonIncludes => """
#import('package:web_components/lib/js_polyfill/component.dart');
#import('package:web_components/watcher.dart');
#import('package:web_components/lib/js_polyfill/web_components.dart');
#import('package:web_components/tools/lib/data_template.dart');
""";

  /**
   *  Epilog of the render function; injects the nodes into the live document
   *  to make everything visible.
   */
  static String renderNodes = @"""


    var nodes = templateRoot.nodes;
    while (nodes.length > 0) {
      parent.nodes.add(nodes[0]);
    }""";

  static String emitExtendsClassHeader(String name, String extendsName,
                                       String body) =>
      "\nclass $name extends $extendsName {\n$body\n}\n";

  static String emitImplementsClassHeader(String name, String implementsName,
                                       String body) =>
      "\nclass $name implements $implementsName {\n$body\n}\n";

  static String emitClass(String className,
                          String extendsName,
                          [String classBodyCode = null,
                           String params = null,
                           String initializer = null,
                           String body = null,
                           List<String> funcs = null,
                           String epilog = null]) {
    StringBuffer buff = new StringBuffer();

    if (classBodyCode != null) {
      buff.add(classBodyCode);
    }

    bool constructParams = params != null && !params.isEmpty();
    buff.add("  $className(${constructParams ? params: ''}) ");

    bool constructInitializer = initializer != null && !initializer.isEmpty();
    buff.add("${constructInitializer ? ': $initializer' : ''}");

    bool constructBody = body != null && !body.isEmpty();
    buff.add("${constructBody ? ' {$body\n  }' : ';'}");

    bool anyFuncs = funcs != null && funcs.length > 0;
    if (anyFuncs) {
      for (String func in funcs) {
        if (func.trim().length > 0) {
          buff.add("\n\n");
          buff.add("  $func");
        }
      }
    }

    if (epilog != null && epilog.length > 0) {
      buff.add(epilog);
    }

    return "${emitExtendsClassHeader(className, extendsName, buff.toString())}";
  }

  static String genInjectsCommentBlock = @"""

  // ==================================================================
  // Injection functions:
  // ==================================================================""";

  static String injectionsCode(ecg) {
    StringBuffer buff = new StringBuffer();

    // Emit all injection functions.
    buff.add(genInjectsCommentBlock);
    var index = 0;
    // TODO(sigmund,terry): are inject_ methods still needed?
    //for (var expr in ecg.expressions) {
    //  buff.add("\n  inject_$index() => safeHTML(model.$expr);");
    //  index++;
    //}

    return buff.toString();
  }

}
