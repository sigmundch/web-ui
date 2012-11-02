// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Part of the template compilation that concerns with simplifying HTML trees to
 * emit trimmed simple HTML code.
 */
library html_cleaner;

import 'package:html5lib/dom.dart';

import 'info.dart';

/** Removes bindings and extra nodes from the HTML assciated with [info]. */
void cleanHtmlNodes(info) {
  new _HtmlCleaner().visit(info);
}

// TODO(jmesserly): see if we can drive this entirely off info, so it doesn't
// duplicate parsing elsewhere in analyzer.
/** Remove all MDV attributes; post-analysis these attributes are not needed. */
class _HtmlCleaner extends InfoVisitor {

  void visitComponentInfo(ComponentInfo info) {
    // Remove the <element> tag from the tree
    if (info.elemInfo != null) info.elemInfo.node.remove();
    super.visitComponentInfo(info);
  }

  void visitElementInfo(ElementInfo info) {
    var node = info.node;
    if (info.isIterateOrIf) {
      // Remove children but not template node itself
      node.nodes.clear();

      // Hide all template elements. At the very least, we must do this for
      // template attributes, such as `<td template instantiate="if cond">`.
      // TODO(jmesserly): should probably inject a stylesheet into the page:
      // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/templates/index.html#css-additions
      if (info.isTemplateElement || info.hasIfCondition) {
        node.attributes['style'] = 'display:none';
      }
    }

    node.attributes.forEach((name, value) {
      visitAttribute(node, name, value);
    });

    if (info.contentBinding != null) {
      // TODO(jmesserly, sigmundch): this looks weird, see issue #133.
      assert(node is Text);
      node.remove();
      return;
    }

    super.visitElementInfo(info);
  }

  void visitAttribute(Element node, String name, String value) {
    switch (name) {
      // Remove MDV attributes now that we've processed them.
      case 'data-action':
      case 'data-bind':
      case 'data-value':
      case 'instantiate':
      case 'iterate':
      case 'template':
        node.attributes.remove(name);
        break;
      default:
        // Remove any attribute computed as a MDV expression.
        if (value.contains("{{")) {
          node.attributes.remove(name);
        }
    }
  }
}
