// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Part of the template compilation that concerns with extracting information
 * from the HTML parse tree.
 */
#library('analyzer');

#import('package:web_components/lib/html5parser/htmltree.dart');
#import('package:web_components/lib/html5parser/tokenkind.dart');
#import('utils.dart');
#import('package:web_components/tools/lib/world.dart');

/** Information extracted for any node in the AST. */
interface NodeInfo {
}

/** Information extracted for each node in a template. */
class ElementInfo implements NodeInfo {

  /** Id given to an element node, if any. */
  String elementId;

  /** Whether the element is a component instantiation. */
  bool isComponent = false;

  /** Whether the element is loop iteration. */
  bool isIterate = false;

  /** Whether the element is conditional. */
  bool isConditional = false;

  /** Whether the element contains data bindings. */
  bool hasDataBinding = false;

  /** Data-bound expression used in the contents of the node. */
  String contentBinding;

  /**
   * Expression that returns the contents of the node (given it has a
   * data-bound expression in it).
   */
  // TODO(terry,sigmund): support more than 1 expression in the contents.
  String contentExpression;

  /** Variable declared on loop iterations (null when `!isIterate`). */
  String iterVariable;

  /** Expression that is used in conditionals. */
  String conditionalExpression;

  /** Expression that is used in loops. */
  String loopExpression;

  /** Collected information for attributes, if any. */
  Map<String, AttributeInfo> attributes;

  /** Collected information for UI events on the corresponding element. */
  Map<String, EventInfo> events;

  /**
   * Format [elementId] in camel case, suitable for using as a Dart identifier.
   */
  String get idAsIdentifier() =>
      elementId == null ? null : '_${toCamelCase(elementId)}';

  ElementInfo() : attributes = <AttributeInfo>{}, events = <EventInfo>{};

  String toString() => 'id: $elementId, '
      'isComponent: $isComponent, '
      'isIterate: $isIterate, '
      'isConditional: $isConditional, '
      'hasDataBinding: $hasDataBinding, '
      'contentBinding: $contentBinding, '
      'contentExpression: $contentExpression, '
      'iterVariable: $iterVariable, '
      'conditionalExpression: $conditionalExpression, '
      'loopExpression: $loopExpression, '
      'attributes: $attributes, '
      'events: $events';
}

/** Information extracted for each attribute in an element. */
class AttributeInfo implements NodeInfo {

  /**
   * Whether this is a `class` attribute. In which case more than one binding
   * is allowed (one per class).
   */
  bool isClass = false;

  /**
   * A value that will be monitored for changes. All attributes, except `class`,
   * have a single bound value.
   */
  String get boundValue => bindings[0];

  /** All bound values that would be monitored for changes. */
  List<String> bindings;

  AttributeInfo(String value) : bindings = [value];
  AttributeInfo.forClass(this.bindings) : isClass = true;

  String toString() =>
      '(isClass: $isClass, values: ${Strings.join(bindings, "")})';
}

/** Information extracted for each declared event in an element. */
class EventInfo implements NodeInfo {
  /** Event name for attributes representing actions. */
  String eventName;

  /** Action associated for event listener attributes. */
  ActionDefinition action;

  EventInfo(this.eventName, this.action);

  String toString() => '(eventName: $eventName, action: $action)';
}

/**
 * Specifies the action to take on a particular event. Some actions need to read
 * attributes from the DOM element that has the event listener (e.g. two way
 * bindings do this). A reference to this element ([elementVarName]) is
 * generated outside of the analyzer, thus, we parameterize actions here.
 */
typedef String ActionDefinition([String elemVarName]);

const String DATA_ON_ATTRIBUTE = "data-on-";

/** Extract relevant information from [source] and it's children. */
Map<TreeNode, NodeInfo> analyze(TreeNode source) {
  var res = new Map<TreeNode, NodeInfo>();
  var analyzer = new _Analyzer(res);
  source.visit(analyzer);
  return res;
}


/** A visitor that walks the HTML to extract all the relevant information. */
class _Analyzer extends RecursiveVisitor implements TreeVisitor {
  final Map<TreeNode, NodeInfo> results;
  final List<TreeNode> _stack;

  _Analyzer(this.results) : _stack = [];

  void visitHTMLElement(HTMLElement node) {
    results[node] = new ElementInfo();
    _stack.add(node);
    super.visitHTMLElement(node);
    var last = _stack.removeLast();
    assert(node === last);
  }

  void visitHTMLAttribute(HTMLAttribute node) {
    if (node.name == "id") {
      (results[_stack.last()] as ElementInfo).elementId = node.value;
    }
  }

  void visitTemplateAttributeExpression(TemplateAttributeExpression node) {
    final HTMLElement elem = _stack.last();
    final ElementInfo elemInfo = results[elem];
    // TODO(sigmund): should this be true if you only have UI event listeners?
    elemInfo.hasDataBinding = true;
    if (node.name.startsWith(DATA_ON_ATTRIBUTE)) {
      // Special data-attribute specifying an event listener.
      var eventInfo = new EventInfo(
          node.name.substring(DATA_ON_ATTRIBUTE.length),
          ([elemVarName]) => node.value);
      results[node] = eventInfo;
      elemInfo.events[eventInfo.eventName] = eventInfo;
      return;
    }

    var name = node.name;
    var attrInfo;
    if (name == 'data-bind') {
      var colonIdx = node.value.indexOf(':');
      if (colonIdx <= 0) {
        world.error('data-bind attribute should be of the form '
            'data-bind="name:value"', node.span);
        return;
      }

      name = node.value.substring(0, colonIdx);
      var value = node.value.substring(colonIdx + 1);
      var isInput = elem.tagTokenId == TokenKind.INPUT_ELEMENT;
      // Special two-way binding logic for input elements.
      if (isInput && name == 'checked') {
        attrInfo = new AttributeInfo(value);
        // TODO(sigmund): deal with conflicts, e.g. I have a click listener too
        if (elemInfo.events['click'] != null) {
          throw const NotImplementedException(
              'a click listener + a data-bound check box');
        }
        elemInfo.events['click'] = new EventInfo('click',
            // Assume [value] is a property with a setter.
            ([elemVarName]) => '$value = $elemVarName.checked');
      } else if (isInput && name == 'value') {
        attrInfo = new AttributeInfo(value);
        if (elemInfo.events['keyUp'] != null) {
          throw const NotImplementedException(
              'a keyUp listener + a data-bound input value');
        }
        elemInfo.events['keyUp'] = new EventInfo('keyUp',
            // Assume [value] is a property with a setter.
            ([elemVarName]) => '$value = $elemVarName.value');
      } else {
        throw "Unknown data-bind attribute: ${elem.tagTokenId} - ${name}";
      }
    } else if (name == 'class') {
      // Special support to bind each css class separately.
      // class="{{class1}} {{class2}} {{class3}}"
      List<String> bindings = [];
      var parts = node.value.split(const RegExp(@'}}\s*{{'));
      for (var part in parts) {
        bindings.add(part);
      }
      attrInfo = new AttributeInfo.forClass(bindings);
    } else {
      // Default to a 1-way binding for any other attribute.
      attrInfo = new AttributeInfo(node.value);
    }
    results[node] = attrInfo;
    elemInfo.attributes[name] = attrInfo;
  }

  void visitTemplateExpression(TemplateExpression node) {
    final HTMLChildren parentElem = _stack.last();
    final ElementInfo info = results[parentElem];
    info.hasDataBinding = true;
    // TODO(sigmund,terry): support more than 1 template expression
    assert(info.contentBinding == null);
    info.contentBinding = node.expression;

    var buf = new StringBuffer();
    for (var content in parentElem.children) {
      if (content is HTMLText) {
        buf.add(content.value);
      } else {
        // TODO(sigmund,terry): support more than 1 template expression
        assert(content == node);
        buf.add("\${${node.expression}}");
      }
    }
    var content = buf.toString().replaceAll("'", "\\'").replaceAll('\n', " ");
    info.contentExpression = "'$content'";
  }
}

