// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Bootstrap polyfill script for custom elements.
 * This script enables defining custom elements with blocks of dart code
 * embedded within an html page just as you would define web components using
 * JavaScript.
 * This script only works with properly with dartium however to use it you must
 * compiled it to JavasScript due to a bug with injecting additional dart
 * scripts into a page after dart code has already run
 * [bug 4636](http://dartbug.com/4636).
 *
 * The script does an XMLHTTP request, so
 * to test using locally defined custom elements you must run chrome with the
 * flag -allow-file-access-from-files.
 */

#library('webcomponents_bootstrap');

#import('dart:html');
#import('dart:uri');

final int REQUEST_DONE = 4;

// TODO(jacobr): with mirror support this list doesn't need to be hard coded.
// You can instead create a test element given a tag name and then determine
// its class.
final _tagToClassName = const {
    'a': 'AnchorElement',
    'area': 'AreaElement',
    'button': 'ButtonElement',
    'br': 'BRElement',
    'base': 'BaseElement',
    'body': 'BodyElement',
    'canvas': 'CanvasElement',
    'dl': 'DListElement',
    'details': 'DetailsElement',
    'div': 'DivElement',
    'embed': 'EmbedElement',
    'fieldset': 'FieldSetElement',
    'footer': 'Element',
    'form': 'Form',
    'hr': 'HRElement',
    'head': 'HeadElement',
    'h1': 'HeadingElement',
    'h2': 'HeadingElement',
    'h3': 'HeadingElement',
    'h4': 'HeadingElement',
    'h5': 'HeadingElement',
    'h6': 'HeadingElement',
    'html': 'HtmlElement',
    'iframe': 'IFrameElement',
    'img':' ImageElement',
    'input': 'InputElement',
    'keygen': 'KeygenElement',
    'li': 'LIElement',
    'label': 'LabelElement',
    'legend': 'LegendElement',
    'link': 'LinkElement',
    'map': 'MapElement',
    'menu': 'MenuElement',
    'meter': 'MeterElement',
    'ol': 'OListElement',
    'object': 'ObjectElement',
    'optgroup': 'OptGroupElement',
    'output': 'OutputElement',
    'p': 'ParagraphElement',
    'param': 'ParamElement',
    'pre': 'PreElement',
    'progress': 'ProgressElement',
    'script': 'ScriptElement',
    'select': 'SelectElement',
    'source': 'SourceElement',
    'span': 'SpanElement',
    'style': 'StyleElement',
    'caption': 'TableCaptionElement',
    'td': 'TableCellElement',
    'col': 'TableColElement',
    'table': 'TableElement',
    'tr': 'TableRowElement',
    // 'TableSectionElement'  <thead> <tbody> <tfoot>
    'template': 'Element', // TODO(jacobr): this is wrong.
    'textarea': 'TextAreaElement',
    'title': 'TitleElement',
    'track': 'TrackElement',
    'ul': 'UListElement',
    'video': 'VideoElement'};

Function _afterN(Function callback, int count) {
  return () {
    assert(count > 0);
    count--;
    if (count == 0) {
      callback();
    }
  };
}

/**
 * Locate all external component files, load each of them, expand
 * declarations and then launch a new isolate containing them.
 */
void loadComponents() {
  var declarations = <CustomElementDeclaration>[];

  var components = queryAll('link[rel=components]');

  var callback = _afterN(() { runComponents(declarations); }, components.length);
  for(var link in components) {
    var request = new HttpRequest();
    request
      ..open('GET', link.href, async: true)
      ..on.readyStateChange.add((Event e) {
        if (request.readyState == REQUEST_DONE) {
          try {
            if (request.status >= 200 && request.status < 300
                || request.status == 304 || request.status == 0) {
              declarations.add(new CustomElementDeclaration(link.href,
                                  new DocumentFragment.html(request.response)));
            } else {
              window.console.error(
                  'Unable to load component: Status ${request.status}'
                  ' - ${request.statusText}');
            }
          } finally {
            callback();
          }
        }
      })
      ..send();
  }
}

String rewritePaths(String script, String url) {
  var location = new Uri.fromString(window.location.href);
  var scriptLocation = location.resolve(url);

  var sb = new StringBuffer();
  for (String line in script.split(new RegExp('\n'))) {
    Match match = const RegExp(@"""^(#import[(]["'])([^"']+)(["'][)];)$""")
        .firstMatch(line);
    if (match != null) {
      var absLocation = scriptLocation.resolve(match.group(2));
      line = "${match.group(1)}$absLocation${match.group(3)}";
    }
    sb..add(line)..add('\n');
  }
  return sb.toString();
}

/// Declaration defining one or more custom elements.
class CustomElementDeclaration {

  /** Url the declaration was loaded from. */
  final String url;

  /**
   * Html containing all custom element definitions specified as part of the
   * script.
   */
  final Element html;

  CustomElementDeclaration(this.url, this.html);
}

int _uniqueId = 0;
String uniqueLibPrefix(String url) {
  // TODO(jacobr): use url.
  _uniqueId++;
  return "lib$_uniqueId";
}

/// Build up a dart file that when executed laads all components on the page.
void runComponents(List<CustomElementDeclaration> declarations) {
  var sbHeader = new StringBuffer();
  var sb = new StringBuffer()
    ..add("""
#import("dart:html");
#import("package:web_components/mirror_polyfill/component_loader.dart", prefix: "polyfill");
""");

  var sbMain = new StringBuffer()..add("void main() {");
  var sbMainFooter = new StringBuffer();
  // TODO(jacobr): this assumes each script imported is a library.
  for (ScriptElement script in queryAll('script[type="application/dart"]')) {
    // TODO(jacobr): fix this hack to keep the scripts from running.
    script.type = "application/dart_MERGED_INTO_ISOLATE";
    if (!script.src.isEmpty()) {
      String url = script.src;
      var libPrefix = uniqueLibPrefix(url);
      // TODO(jacobr): proper escaping.
      sb.add('#import("$url", prefix: "$libPrefix");\n');
      sbMainFooter.add("""
  // TODO(jacobr): enclose in try-catch block.
  $libPrefix.main();
""");
    }
  }

  for(CustomElementDeclaration declaration in declarations) {
    var sbLibrary = new StringBuffer();
    var sbLibraryHeader = new StringBuffer();

    var topLevelScripts = declaration.html.queryAll(
        'script[type="application/dart"]').filter(
        (Element e) => e.parent.tagName != "ELEMENT");
    // For simplicity we assume at most one top level script.
    assert(topLevelScripts.length <= 1);
    for (ScriptElement script in topLevelScripts) {
      sbLibraryHeader
        ..add(rewritePaths(script.text, declaration.url))
        ..add("\n");
    }

    String libraryName =
        const RegExp(@"([^/.]+)([^/]+)$").firstMatch(
            new Uri(declaration.url).path).group(1);
    sbLibrary.add("""
#library("$libraryName");
#import("package:web_components/mirror_polyfill/component_loader.dart", prefix: "polyfill");
#import("package:web_components/mirror_polyfill/component.dart", prefix: "polyfill");
$sbLibraryHeader
""");

    int numDartCustomElements = 0;
    for(Element element in declaration.html.queryAll('element')) {
      String tag = element.attributes['name'];
      String className = element.attributes['constructor'];

      bool applyAuthorStyles = element.attributes.containsKey(
          'apply-author-styles');
      if (tag == null || tag.length == 0) {
        // TODO(samhop): friendlier errors
        window.console.error('name attribute is required');
        continue;
      }
      var extendz = element.attributes['extends'];
      if (extendz == null || extendz.length == 0) {
        window.console.error('extends attribute is required');
        continue;
      }
      if (className == null || className.length == 0) {
        // TODO(jacobr): relax this requirement.
        window.console.error('constructor attribute required for now');
        continue;
      }
      var template = element.query('template');
      ScriptElement script = element.query('script[type="application/dart"]');
      if (script == null) {
        // TODO(jacobr): relax this requirement.
        window.console.warn("Skipped $className as no script body specified");
        continue;
      }
      numDartCustomElements++;
      if (script.src.isEmpty()) {
        var classBody = script.text;
        sbLibrary.add("""
class $className extends polyfill.Component implements ${_tagToClassName[extendz]} {

  $className(element) : super('$className', element);

$classBody
}
""");
      } else {
        // TODO(jacobr): move these 3 lines into a helper method.
        var location = new Uri.fromString(window.location.href);
        var scriptLocation = location.resolve(declaration.url);
        var absLocation = scriptLocation.resolve(script.src);
        sbLibrary.add("""
#import('dart:html');
#import("$absLocation");
""");
      }

      sbLibrary.add("""
// TODO(jacobr): support more than one component per library.
void register() {
  polyfill.registerComponent(new polyfill.CustomDeclaration("$tag", "$extendz",
      new Element.html(@'''${template.outerHTML}'''),
      true, "$className"));
}
""");

    }
    if (numDartCustomElements == 0) continue;

    var dataUrl =
        "data:application/dart;base64,${window.btoa(sbLibrary.toString())}";

    sb.add('#import(@"""$dataUrl""", prefix: "$libraryName");\n');
    sbMain.add("  ${libraryName}.register();\n");

    // TODO(jacobr): remove this once b/4344 is fixed. This script tag is
    // inserted into the page to make the debugging experience tollerable.
   document.head.nodes
     .add(
       new ScriptElement()
         ..text = """
$sbLibrary

void main() {
  print("Test that the library compiles. ignore.");
}
"""
        ..type = "application/dart");

  }
  sb.add("""
$sbMain
  polyfill.initializeComponents();
$sbMainFooter
}
""");

  // Inject the output dart script on the page and the dart.js bootstrap script.
  var protocol = window.location.protocol;
  if (protocol == 'file:') protocol = 'http:';
  document.head.nodes
   ..add(
     new ScriptElement()
       ..text = "$sb"
       ..type = "application/dart")
    ..add(
      new ScriptElement()
        ..src = "$protocol//dart.googlecode.com/svn/branches/bleeding_edge/"
                "dart/client/dart.js"
        ..type = "application/javascript");

}

void main() {
  loadComponents();
}
