// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Part of the template compilation that concerns with extracting information
 * from the HTML parse tree.
 */
#library('analyzer');

#import('package:html5lib/treebuilders/simpletree.dart');
#import('package:web_components/tools/lib/world.dart');
#import('utils.dart');


/** Information extracted for any node in the AST. */
interface NodeInfo {
}

/** Information extracted for each node in a template. */
class ElementInfo implements NodeInfo {

  /** Id given to an element node, if any. */
  String elementId;

  /** Generated field name, if any, associated with this element. */
  // TODO(sigmund): move this to Emitter?
  String elemField;

  /**
   * Whether code generators need to create a field to store a reference to this
   * element. This is typically true whenever we need to access the element
   * (e.g. to add event listeners, update values on data-bound watchers, etc).
   */
  bool get needsHtmlId =>
      events.length > 0 || hasDataBinding || hasIfCondition || isIterate;

  /** The name of a component (use of is attribute). */
  String componentName;

  /** Whether the element is a component instantiation. */
  bool isComponent = false;

  /** Whether the element is loop iteration. */
  bool isIterate = false;

  /** Whether the element is conditional. */
  bool hasIfCondition = false;

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

  /** Generated watcher disposer that watchs for the content expression. */
  // TODO(sigmund): move somewhere else?
  String stopperName;

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

  /** Generate an id's for any HTML element w/o an id attribute. */
  static int _uniqueId = 0;
  static int nextElementId() => _uniqueId++;

  ElementInfo() : attributes = <AttributeInfo>{}, events = <EventInfo>{};

  String toString() => 'id: $elementId, '
      'isComponent: $isComponent, '
      'isIterate: $isIterate, '
      'hasIfCondition: $hasIfCondition, '
      'hasDataBinding: $hasDataBinding, '
      'contentBinding: $contentBinding, '
      'contentExpression: $contentExpression, '
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

  /**
   * Generated fields for watcher disposers based on the bindings of this
   * attribute.
   */
  List<String> stopperNames;
}

/** Information extracted for each declared event in an element. */
class EventInfo implements NodeInfo {
  /** Event name for attributes representing actions. */
  String eventName;

  /** Generated field name, if any, associated with this event. */
  String listenerField;

  /** Action associated for event listener attributes. */
  ActionDefinition action;

  EventInfo(this.eventName, this.action);

  String toString() => '(eventName: $eventName, action: $action)';
}

// TODO(jmesserly): I'm not sure we need this, but it was useful for
// bootstrapping the switch to the html5 parser.
class TemplateInfo extends ElementInfo {
  static const String LIST_COMPONENT = "x-list";
  static const String IF_COMPONENT = "x-if";

  final String instantiate;
  final String iterate;

  TemplateInfo(this.instantiate, this.iterate) {
    if (!iterate.isEmpty()) {
      isIterate = true;
      componentName = LIST_COMPONENT;
    }
  }

  bool get hasIfCondition => instantiate.startsWith('if ');

  String get ifCondition {
    if (!hasIfCondition) {
      throw new UnsupportedOperationException(
          'not a <template iterate="if ..."> node');
    }
    return instantiate.substring(3);
  }
}


/**
 * Specifies the action to take on a particular event. Some actions need to read
 * attributes from the DOM element that has the event listener (e.g. two way
 * bindings do this). A reference to this element ([elementVarName]) is
 * generated outside of the analyzer, thus, we parameterize actions here.
 */
typedef String ActionDefinition([String elemVarName]);


/** Extract relevant information from [source] and it's children. */
Map<Node, NodeInfo> analyze(Node source) {
  return (new _Analyzer()..visit(source)).results;
}

/** A visitor that walks the HTML to extract all the relevant information. */
class _Analyzer extends TreeVisitor {
  static const String _DATA_ON_ATTRIBUTE = "data-on-";

  final Map<Node, NodeInfo> results;
  int _totalIds = 0;

  _Analyzer() : results = new Map<Node, NodeInfo>();

  void visitElement(Element node) {
    ElementInfo info = null;
    if (node.tagName == 'template') {
      // template tags are handled specially.
      info = createTemplateInfo(node);
    }

    if (info == null) {
      info = new ElementInfo();
    }
    if (node.id != '') info.elementId = node.id;
    results[node] = info;

    node.attributes.forEach((name, value) {
      visitAttribute(node, info, name, value);
    });

    super.visitElement(node);

    // Need to get to this element at codegen time; for template, data binding,
    // or event hookup.  We need an HTML id attribute for this node.
    if (info.needsHtmlId) {
      if (info.elementId == null) {
        info.elementId = "__id-${ElementInfo.nextElementId()}";
        node.attributes['id'] = info.elementId;
      }
      info.elemField = info.idAsIdentifier;
    }
  }

  TemplateInfo createTemplateInfo(Element node) {
    assert(node.tagName == 'template');
    var instantiate = node.attributes['instantiate'];
    var iterate = node.attributes['iterate'];

    if (instantiate != null && iterate != null) {
      // TODO(jmesserly): get the node's span here
      world.error('Template cannot have iterate and instantiate attributes');
      return null;
    }

    if (instantiate == null) instantiate = "";
    if (iterate == null) iterate = "";

    return new TemplateInfo(instantiate, iterate);
  }

  void visitAttribute(Element elem, ElementInfo elemInfo, String name,
                      String value) {
    if (name == 'is') {
      elemInfo.componentName = value;
    }

    var match = const RegExp(@'^\s*{{(.*)}}\s*$').firstMatch(value);
    if (match == null) return;

    // Bound attribute.

    // Strip off the outer {{ }}.
    value = match[1];

    // TODO(sigmund): should this be true if you only have UI event listeners?
    elemInfo.hasDataBinding = true;
    if (name.startsWith(_DATA_ON_ATTRIBUTE)) {
      // Special data-attribute specifying an event listener.
      var eventInfo = new EventInfo(
          name.substring(_DATA_ON_ATTRIBUTE.length),
          ([elemVarName]) => value);
      elemInfo.events[eventInfo.eventName] = eventInfo;
      return;
    }

    var attrInfo;
    if (name == 'data-bind') {
      var colonIdx = value.indexOf(':');
      if (colonIdx <= 0) {
        // TODO(jmesserly): get the node's span here
        world.error('data-bind attribute should be of the form '
            'data-bind="name:value"');
        return;
      }

      name = value.substring(0, colonIdx);
      value = value.substring(colonIdx + 1);
      var isInput = elem.tagName == 'input';
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
        throw new UnsupportedOperationException(
            "Unknown data-bind attribute: ${elem.tagName} - ${name}");
      }
    } else if (name == 'class') {
      // Special support to bind each css class separately.
      // class="{{class1}} {{class2}} {{class3}}"
      List<String> bindings = [];
      var parts = value.split(const RegExp(@'}}\s*{{'));
      for (var part in parts) {
        bindings.add(part);
      }
      attrInfo = new AttributeInfo.forClass(bindings);
    } else {
      // Default to a 1-way binding for any other attribute.
      attrInfo = new AttributeInfo(value);
    }

    elemInfo.attributes[name] = attrInfo;
  }

  void visitText(Text text) {
    var bindingRegex = const RegExp(@'{{(.*)}}');
    if (!bindingRegex.hasMatch(text.value)) return;

    var parentElem = text.parent;
    ElementInfo info = results[parentElem];
    info.hasDataBinding = true;
    assert(info.contentBinding == null);

    // Match all bindings.
    var buf = new StringBuffer();
    int offset = 0;
    for (var match in bindingRegex.allMatches(text.value)) {
      var binding = match[1];
      // TODO(sigmund,terry): support more than 1 template expression
      if (info.contentBinding == null) {
        info.contentBinding = binding;
      }

      buf.add(text.value.substring(offset, match.start()));
      buf.add("\${$binding}");
      offset = match.end();
    }
    buf.add(text.value.substring(offset));

    var content = buf.toString().replaceAll("'", "\\'").replaceAll('\n', " ");
    info.contentExpression = "'$content'";
  }
}
