// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Part of the template compilation that concerns with extracting information
 * from the HTML parse tree.
 */
library analyzer;

import 'dart:coreimpl';
import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';

import 'directive_parser.dart' show parseDartCode;
import 'file_system/path.dart';
import 'files.dart';
import 'info.dart';
import 'messages.dart';
import 'utils.dart';

/**
 * Finds custom elements in this file and the list of referenced files with
 * component declarations. This is the first pass of analysis on a file.
 */
FileInfo analyzeDefinitions(SourceFile file, {bool isEntryPoint: false}) {
  var result = new FileInfo(file.path, isEntryPoint);
  new _ElementLoader(result).visit(file.document);
  return result;
}

/**
 * Extract relevant information from [source] and it's children.
 * Used for testing.
 */
// TODO(jmesserly): move this into analyzer_test
FileInfo analyzeNode(Node source, [bool cleanup = false]) {
  var result = new FileInfo();
  new _Analyzer(result).run(source);
  if (cleanup) {
    new _CleanupHtml(result).visit(source);
  }
  return result;
}

/** Extract relevant information from all files found from the root document. */
void analyzeFile(SourceFile file, Map<Path, FileInfo> info) {
  var fileInfo = info[file.path];
  _normalize(fileInfo, info);
  new _Analyzer(fileInfo).run(file.document);
  new _CleanupHtml(fileInfo).visit(file.document);
}

/** Remove all MDV attributes; post-analysis these attributes are not needed. */
class _CleanupHtml extends TreeVisitor {
  final FileInfo result;

  _CleanupHtml(this.result);

  void visitElement(Element node) {
    node.attributes.forEach((name, value) {
      visitAttribute(node, name, value);
    });

    super.visitElement(node);
  }

  // TODO(terry): Compute the text node data-bound expressions during analysis
  //              time.  Either cleanup DOM then or marked as text node to be
  //              remove.  Also, consider doing the same for class attribute and
  //              other attributes with data-binding too.
  /** Remove text nodes with MDV expr {{ }}, they're handled at runtime. */
  visitText(Text node) {
    var bindingRegex = const RegExp(r'{{(.*)}}');
    if (bindingRegex.hasMatch(node.value)) {
      node.remove();
    }
  }

  void visitAttribute(Element node, String name, String value) {
    switch (name) {
      // Remove all MDV attributes.
      case 'data-value':
      case 'data-action':
      case 'data-bind':
      case 'template':
      case 'iterate':
      case 'instantiate':
        node.attributes.remove(name);
        break;
      default:
        // Remove any attribute computed as a MDV expression.
        var bindingRegex = const RegExp(r'{{(.*)}}');
        if (bindingRegex.hasMatch(value)) {
          node.attributes.remove(name);
        }
    }
  }
}

/** A visitor that walks the HTML to extract all the relevant information. */
class _Analyzer extends TreeVisitor {
  final FileInfo _fileInfo;
  LibraryInfo _currentInfo;
  int _uniqueId = 0;
  final List<ElementInfo> _parents = [];

  _Analyzer(this._fileInfo) {
    _currentInfo = _fileInfo;
    _parents.add(new ElementInfo());
  }

  void run(var node) {
    visit(node);
    assert(_parents.length == 1);
    _fileInfo.bodyInfo = _parents.last;
  }

  void visitElement(Element node) {
    var info = null;
    if (node.tagName == 'script') {
      // We already extracted script tags in previous phase.
      return;
    }

    // Bind to the parent element.
    if (node.attributes.containsKey('template') || node.tagName == 'template') {
      // template tags are handled specially.
      info = _createTemplateInfo(node);
    }

    if (info == null) {
      info = _createElementInfo();
    }
    if (node.id != '') info.elementId = node.id;

    info.node = node;

    if (info is TemplateInfo &&
        (info as TemplateInfo).isTemplateTagAndIterOrIf) {
      var parentNode = info.parent.node;
      if (parentNode != null && parentNode.tagName != 'body') {
        _generateId(parentNode, info.parent, true);
      }  else {
        _generateId(node, info, true);
      }
    }

    node.attributes.forEach((name, value) {
      visitAttribute(node, info, name, value);
    });

    _bindCustomElement(node, info);

    var lastInfo = _currentInfo;
    if (node.tagName == 'element') {
      // If element is invalid _ElementLoader already reported an error, but
      // we skip the body of the element here.
      var name = node.attributes['name'];
      if (name == null) return;
      var component = _fileInfo.components[name];
      if (component == null) return;

      // Associate ElementInfo of the <element> tag with its component.
      component.elemInfo = info;

      // The body of an element tag will not be part of the HTML page. Each
      // element will be generated programatically as a Dart web component by
      // [WebComponentEmitter]. So this component's ElementInfo isn't part of
      // the HTML page's children and the ElementInfo is the top-level node.
      info.parent.children.removeLast();
      info.parent = null;

      _bindExtends(component);

      _currentInfo = component;
    }

    _parents.add(info);

    // Invoke super to visit children.
    super.visitElement(node);
    _currentInfo = lastInfo;
    _parents.removeLast();

    bool force = false;
    if (info.parent != null && info.parent.isIterateOrIf) {
      // Conditional template at top level the template child will need an id
      // for DOM element.
      if (lastInfo is ComponentInfo) {
        force = _componentParentsAreTemplates(info);
      } else {
        force = _isToplevelTemplateElement(node);
      }
    }
    _generateId(node, info, force);
  }

  /** Conditional/iterate template at top-level of page sibling of <body>. */
  bool _isToplevelTemplateElement(Node node) {
    if (node != null && node.parent != null && node.parent.parent != null) {
      // TODO(terry): Need to figure out way to know how to add to body not
      //              just an arbitrary element; for this case a template will
      //              be realized and we'll add our children to this template.
      return node.parent.parent.tagName == 'body';
    }
    return false;
  }

  /**
   * For components only, if child element [info] is in a template and it's
   * parents (upto the element tag) are templates then the template will need
   * to be realized in the document; so it will need an id.
   * */
  bool _componentParentsAreTemplates(info) {
    if (info.parent != null) {
      if (info.parent.node is Element &&
          info.parent.node.tagName == 'template') {
        return _componentParentsAreTemplates(info.parent);
      } else if (info.parent.node is Element &&
          info.parent.node.tagName == 'element') {
        return true;
      }
    } else {
      return false;
    }
  }

  /**
   * Need to get to this element at codegen time; for template, data binding,
   * or event hookup.  We need an HTML id attribute for this node.
   */
  void _generateId(Element node, ElementInfo info, [bool forceId = false]) {
    if (!info.needsHtmlId && !forceId) return;
    if (info.elementId != null) return;

    info.elementId = "__e-${_uniqueId}";

    var parentNode = info.parent.node;

    if (_needsIdentifier(info, parentNode, node) ||
        _topLevelDataBindingComponent(info, parentNode)) {
      node.attributes['id'] = info.elementId;
      info.useDomId = true;
    }

    _uniqueId++;
  }

  /**
   * Don't need an id attribute generated for the HTML element if the element
   * is a template inside of another template.  If a template is not a lone
   * child element then template is exposed. The id is used only as a variable
   * name in the generated code no need to query to find the HTML element.
   */
  bool _needsIdentifier(ElementInfo info, Node parentNode, Node node) =>
      (info.parent is! TemplateInfo && parentNode != null &&
       parentNode.tagName != 'body') &&
      (node.tagName != 'template' || _moreThanOneChildElement(info.parent));

  // TODO(terry): Need better way for sibling templates too.
  /** Assign an id to the element tag, it's at the top (parent is body). */
  bool _topLevelDataBindingComponent(ElementInfo info, Node parent) =>
    (info is TemplateInfo && parent != null && parent.tagName == 'body') ||
      info.hasDataBinding || info.component != null;

  void _bindExtends(ComponentInfo component) {
    if (component.extendsTag == null) {
      // TODO(jmesserly): is web components spec going to have a default
      // extends?
      messages.error('Missing the "extends" tag of the component. Please '
          'include an attribute like \'extends="div"\'.',
          component.element.span, file: _fileInfo.path);
      return;
    }

    component.extendsComponent = _fileInfo.components[component.extendsTag];
    if (component.extendsComponent == null &&
        component.extendsTag.startsWith('x-')) {

      messages.warning(
          'custom element with tag name ${component.extendsTag} not found.',
          component.element.span, file: _fileInfo.path);
    }
  }

  // TODO(terry): Can remove this function and replace with
  //              node.parent.elements.length > 1 when this is resolved
  //              https://github.com/dart-lang/html5lib/issues/33
  /** More than one child element tag. */
  bool _moreThanOneChildElement(ElementInfo elemInfo) {
    if (elemInfo != null) {
      int childElems = 0;
      for (var node in elemInfo.node.nodes) {
        if (node is Element) {
          if (++childElems > 1)  return true;
        }
      }
    }
    return false;
  }

  void _bindCustomElement(Element node, ElementInfo info) {
    // <x-fancy-button>
    var component = _fileInfo.components[node.tagName];
    if (component == null) {
      // TODO(jmesserly): warn for unknown element tags?

      // <button is="x-fancy-button">
      var isAttr = node.attributes['is'];
      if (isAttr != null) {
        component = _fileInfo.components[isAttr];
        if (component == null) {
          messages.warning('custom element with tag name $isAttr not found.',
              node.span, file: _fileInfo.path);
        }
      }
    }

    if (component != null && !component.hasConflict) {
      info.component = component;
      _currentInfo.usedComponents[component] = true;
    }
  }

  void _setupParentChild(var info) {
    info.parent = _parents.last;
    info.parent.children.add(info);
  }

  ElementInfo _createElementInfo() {
    var info = new ElementInfo();
    _setupParentChild(info);
    return info;
  }

  TemplateInfo _createTemplateInfo(Element node) {
    var instantiate = node.attributes['instantiate'];
    var iterate = node.attributes['iterate'];
    bool templateAttr = node.tagName != 'template' &&
        node.attributes.containsKey('template');

    // Note: we issue warnings instead of errors because the spirit of HTML and
    // Dart is to be forgiving.
    if (instantiate != null && iterate != null) {
      messages.warning('<template> element cannot have iterate and instantiate '
          'attributes', node.span, file: _fileInfo.path);
      return null;
    }

    if (instantiate != null) {
      if (instantiate.startsWith('if ')) {
        var info = new TemplateInfo(ifCondition: instantiate.substring(3),
            isAttribute: templateAttr);
        _setupParentChild(info);
        return info;
      }

      // TODO(jmesserly): we need better support for <template instantiate>
      // as it exists in MDV. Right now we ignore it, but we provide support for
      // data binding everywhere.
      if (instantiate != '') {
        messages.warning('<template instantiate> either have  '
          ' form <template instantiate="if condition" where "condition" is a'
          ' binding that determines if the contents of the template will be'
          ' inserted and displayed.', node.span, file: _fileInfo.path);
      }
    } else if (iterate != null) {
      var match = const RegExp(r"(.*) in (.*)").firstMatch(iterate);
      if (match != null) {
        var info = new TemplateInfo(loopVariable: match[1], loopItems: match[2],
            isAttribute: templateAttr);
        _setupParentChild(info);
        return info;
      }
      messages.warning('<template> iterate must be of the form: '
          'iterate="variable in list", where "variable" is your variable name'
          ' and "list" is the list of items.',
          node.span, file: _fileInfo.path);
    }
    return null;
  }

  void visitAttribute(Element elem, ElementInfo elemInfo, String name,
                      String value) {
    if (name == 'data-value') {
      _readDataValueAttribute(elem, elemInfo, value);
      return;
    } else if (name == 'data-action') {
      _readDataActionAttribute(elem, elemInfo, value);
      return;
    }

    if (name == 'data-bind') {
      _readDataBindAttribute(elem, elemInfo, value);
    } else {
      if (name == 'class') {
        elemInfo.attributes[name] = _readClassAttribute(elem, elemInfo, value);
      } else {
        // Strip off the outer {{ }}.
        var match = const RegExp(r'^\s*{{(.*)}}\s*').firstMatch(value);
        if (match == null) return;
        value = match[1];

        // Default to a 1-way binding for any other attribute.
        elemInfo.attributes[name] = new AttributeInfo(value);
      }
    }
    elemInfo.hasDataBinding = true;
  }

  void _readDataValueAttribute(
      Element elem, ElementInfo elemInfo, String value) {
    var colonIdx = value.indexOf(':');
    if (colonIdx <= 0) {
      messages.error('data-value attribute should be of the form '
          'data-value="name:value"', elem.span, file: _fileInfo.path);
      return;
    }
    var name = value.substring(0, colonIdx);
    value = value.substring(colonIdx + 1);

    elemInfo.values[name] = value;
  }

  void _readDataActionAttribute(
      Element elem, ElementInfo elemInfo, String value) {
    // Bind each event, stopping if we hit an error.
    for (var action in value.split(',')) {
      if (!_readDataAction(elem, elemInfo, action)) return;
    }
  }

  bool _readDataAction(Element elem, ElementInfo elemInfo, String value) {
    // Special data-attribute specifying an event listener.
    var colonIdx = value.indexOf(':');
    if (colonIdx <= 0) {
      messages.error('data-action attribute should be of the form '
          'data-action="eventName:action", or data-action='
          '"eventName1:action1,eventName2:action2,..." for multiple events.',
          elem.span, file: _fileInfo.path);
      return false;
    }

    var name = value.substring(0, colonIdx);
    value = value.substring(colonIdx + 1);
    _addEvent(elemInfo, name, (elem, args) => '${value}($args)');
    return true;
  }

  void _addEvent(ElementInfo elemInfo, String name, ActionDefinition action) {
    var events = elemInfo.events.putIfAbsent(name, () => <EventInfo>[]);
    events.add(new EventInfo(name, action));
  }

  AttributeInfo _readDataBindAttribute(
      Element elem, ElementInfo elemInfo, String value) {
    var colonIdx = value.indexOf(':');
    if (colonIdx <= 0) {
      messages.error('data-bind attribute should be of the form '
          'data-bind="name:value"', elem.span, file: _fileInfo.path);
      return null;
    }

    var attrInfo;
    var name = value.substring(0, colonIdx);
    value = value.substring(colonIdx + 1);
    var isInput = elem.tagName == 'input';
    // Special two-way binding logic for input elements.
    if (isInput && name == 'checked') {
      attrInfo = new AttributeInfo(value);
      // Assume [value] is a field or property setter.
      _addEvent(elemInfo, 'click', (elem, args) => '$value = $elem.checked');
    } else if (isInput && name == 'value') {
      attrInfo = new AttributeInfo(value);
      // Assume [value] is a field or property setter.
      _addEvent(elemInfo, 'input', (elem, args) => '$value = $elem.value');
    } else {
      messages.error('Unknown data-bind attribute: ${elem.tagName} - ${name}',
          elem.span, file: _fileInfo.path);
      return null;
    }
    elemInfo.attributes[name] = attrInfo;
  }

  /**
   * Special support to bind each css class separately.
   *
   *       class="{{class1}} class2 {{class3}} {{class4}}"
   *
   * Returns list of databound expressions (e.g, class1, class3 and class4).
   */
  AttributeInfo _readClassAttribute(
      Element elem, ElementInfo elemInfo, String value) {

    var bindings = <String>[];
    if (value != null) {
      var parser = new BindingParser(value);
      var content = new StringBuffer();
      while (parser.moveNext()) {
        content.add(parser.textContent);
        bindings.add(parser.binding);
      }
      content.add(parser.textContent);

      // Update class attributes to only have non-databound class names for
      // attributes for the HTML.
      elem.attributes['class'] = content.toString();
    }

    return new AttributeInfo.forClass(bindings);
  }

  void visitText(Text text) {
    var info = _createElementInfo();

    // TODO(terry): ElementInfo Should associated with elements, rather than
    // nodes. In this case, we are creating a text node, so we should maybe
    // have a 'NodeInfo' rather than an 'ElementInfo' in that case.
    info.node = text;

    var parser = new BindingParser(text.value);
    if (!parser.moveNext()) return;

    var parentElem = text.parent;
    info.parent.hasDataBinding = true;
    info.hasDataBinding = true;
    assert(info.parent.contentBinding == null);

    // Match all bindings.
    var content = new StringBuffer();
    var bindings = [];
    do {
      bindings.add(parser.binding);
      content.add(escapeDartString(parser.textContent));

      // Note: bindings themselves are Dart expressions (currently--see #65).
      // So we should not need to further escape them.
      content.add("\${${parser.binding}}");
    } while (parser.moveNext());

    content.add(escapeDartString(parser.textContent));

    if (bindings.length == 1) {
      info.contentBinding = bindings[0];
    } else {
      // TODO(jmesserly): we could probably do something faster than a list
      // for watching on multiple bindings. But it seems easy to get working.
      info.contentBinding = '[${Strings.join(bindings, ", ")}]';
    }
    info.contentExpression = "'$content'";

    // Parent Element needs an id; this text node has a template expression.
    var parentNode = info.parent.node;
    _generateId(parentNode, info.parent, true);
  }
}

/** A visitor that finds `<link rel="components">` and `<element>` tags.  */
class _ElementLoader extends TreeVisitor {
  final FileInfo _fileInfo;
  LibraryInfo _currentInfo;
  bool _inHead = false;

  _ElementLoader(this._fileInfo) {
    _currentInfo = _fileInfo;
  }

  void visitElement(Element node) {
    switch (node.tagName) {
      case 'link': visitLinkElement(node); break;
      case 'element': visitElementElement(node); break;
      case 'script': visitScriptElement(node); break;
      case 'head':
        var savedInHead = _inHead;
        _inHead = true;
        super.visitElement(node);
        _inHead = savedInHead;
        break;
      default: super.visitElement(node); break;
    }
  }

  void visitLinkElement(Element node) {
    if (node.attributes['rel'] != 'components') return;

    if (!_inHead) {
      messages.warning('link rel="components" only valid in '
          'head.', node.span, file: _fileInfo.path);
      return;
    }

    var href = node.attributes['href'];
    if (href == null || href == '') {
      messages.warning('link rel="components" missing href.',
          node.span, file: _fileInfo.path);
      return;
    }


    var path = _fileInfo.path.directoryPath.join(new Path(href));
    _fileInfo.componentLinks.add(path);
  }

  void visitElementElement(Element node) {
    // TODO(jmesserly): what do we do in this case? It seems like an <element>
    // inside a Shadow DOM should be scoped to that <template> tag, and not
    // visible from the outside.
    if (_currentInfo is ComponentInfo) {
      messages.error('Nested component definitions are not yet supported.',
          node.span, file: _fileInfo.path);
      return;
    }

    var component = new ComponentInfo(node, _fileInfo);
    if (component.constructor == null) {
      messages.error('Missing the class name associated with this component. '
          'Please add an attribute of the form  \'constructor="ClassName"\'.',
          node.span, file: _fileInfo.path);
      return;
    }

    if (component.tagName == null) {
      messages.error('Missing tag name of the component. Please include an '
          'attribute like \'name="x-your-tag-name"\'.',
          node.span, file: _fileInfo.path);
      return;
    }

    if (component.template == null) {
      messages.warning('an <element> should have exactly one <template> child.',
          node.span, file: _fileInfo.path);
    }

    _fileInfo.declaredComponents.add(component);

    var lastInfo = _currentInfo;
    _currentInfo = component;
    super.visitElement(node);
    _currentInfo = lastInfo;
  }


  void visitScriptElement(Element node) {
    var scriptType = node.attributes['type'];
    if (scriptType == null) {
      // Note: in html5 leaving off type= is fine, but it defaults to
      // text/javascript. Because this might be a common error, we warn about it
      // and force explicit type="text/javascript".
      // TODO(jmesserly): is this a good warning?
      messages.warning('ignored script tag, possibly missing '
          'type="application/dart" or type="text/javascript":',
          node.span, file: _fileInfo.path);
    }

    if (scriptType != 'application/dart') return;

    var src = node.attributes["src"];
    if (src != null) {
      if (!src.endsWith('.dart')) {
        messages.warning('"application/dart" scripts should'
            'use the .dart file extension.',
            node.span, file: _fileInfo.path);
      }

      if (node.innerHTML.trim() != '') {
        messages.error('script tag has "src" attribute and also has script '
            ' text.', node.span, file: _fileInfo.path);
      }

      if (_currentInfo.codeAttached) {
        _tooManyScriptsError(node);
      } else {
        _currentInfo.externalFile =
            _fileInfo.path.directoryPath.join(new Path(src));
      }
      return;
    }

    if (node.nodes.length == 0) return;

    // I don't think the html5 parser will emit a tree with more than
    // one child of <script>
    assert(node.nodes.length == 1);
    Text text = node.nodes[0];

    if (_currentInfo.codeAttached) {
      _tooManyScriptsError(node);
    } else if (_currentInfo == _fileInfo && !_fileInfo.isEntryPoint) {
      messages.warning('top-level dart code is ignored on '
          ' HTML pages that define components, but are not the entry HTML '
          'file.', node.span, file: _fileInfo.path);
    } else {
      _currentInfo.inlinedCode = text.value;
      _currentInfo.userCode = parseDartCode(text.value,
          _currentInfo.inputPath, messages);
      if (_currentInfo.userCode.partOf != null) {
        messages.error('expected a library, not a part.',
            node.span, file: _fileInfo.path);
      }
    }
  }

  void _tooManyScriptsError(Node node) {
    var location = _currentInfo is ComponentInfo ?
        'a custom element declaration' : 'the top-level HTML page';

    messages.error('there should be only one dart script tag in $location.',
        node.span, file: _fileInfo.path);
  }
}

/**
 * Normalizes references in [info]. On the [analyzeDefinitions] phase, the
 * analyzer extracted names of files and components. Here we link those names to
 * actual info classes. In particular:
 *   * we initialize the [components] map in [info] by importing all
 *     [declaredComponents],
 *   * we scan all [componentLinks] and import their [declaredComponents],
 *     using [files] to map the href to the file info. Names in [info] will
 *     shadow names from imported files.
 *   * we fill [externalCode] on each component declared in [info].
 */
void _normalize(FileInfo info, Map<Path, FileInfo> files) {
  _attachExtenalScript(info, files);

  for (var component in info.declaredComponents) {
    _addComponent(info, component);
    _attachExtenalScript(component, files);
  }

  for (var link in info.componentLinks) {
    var file = files[link];
    // We already issued an error for missing files.
    if (file == null) continue;
    file.declaredComponents.forEach((c) => _addComponent(info, c));
  }
}

/**
 * Stores a direct reference in [info] to a dart source file that was loaded in
 * a `<script src="">` tag.
 */
void _attachExtenalScript(LibraryInfo info, Map<Path, FileInfo> files) {
  var path = info.externalFile;
  if (path != null) {
    info.externalCode = files[path];
    info.userCode = info.externalCode.userCode;
  }
}

/** Adds a component's tag name to the names in scope for [fileInfo]. */
void _addComponent(FileInfo fileInfo, ComponentInfo componentInfo) {
  var existing = fileInfo.components[componentInfo.tagName];
  if (existing != null) {
    if (existing == componentInfo) {
      // This is the same exact component as the existing one.
      return;
    }

    if (existing.declaringFile == fileInfo &&
        componentInfo.declaringFile != fileInfo) {
      // Components declared in [fileInfo] are allowed to shadow component
      // names declared in imported files.
      return;
    }

    if (existing.hasConflict) {
      // No need to report a second error for the same name.
      return;
    }

    existing.hasConflict = true;

    if (componentInfo.declaringFile == fileInfo) {
      messages.error('duplicate custom element definition for '
          '"${componentInfo.tagName}".',
          existing.element.span, file: fileInfo.path);
      messages.error('duplicate custom element definition for '
          '"${componentInfo.tagName}" (second location).',
          componentInfo.element.span, file: fileInfo.path);
    } else {
      messages.error('imported duplicate custom element definitions '
          'for "${componentInfo.tagName}".',
          existing.element.span,
          file: existing.declaringFile.path);
      messages.error('imported duplicate custom element definitions '
          'for "${componentInfo.tagName}" (second location).',
          componentInfo.element.span,
          file: componentInfo.declaringFile.path);
    }
  } else {
    fileInfo.components[componentInfo.tagName] = componentInfo;
  }
}


/**
 * Parses double-curly data bindings within a string, such as
 * `foo {{bar}} baz {{quux}}`.
 *
 * Note that a double curly always closes the binding expression, and nesting
 * is not supported. This seems like a reasonable assumption, given that these
 * will be specified for HTML, and they will require a Dart or JavaScript
 * parser to parse the expressions.
 */
class BindingParser {
  final String text;
  int previousEnd;
  int start;
  int end = 0;

  BindingParser(this.text);

  int get length => text.length;

  String get textContent {
    if (start == null) throw new StateError('iteration not started');
    return text.substring(previousEnd, start);
  }

  String get binding {
    if (start == null) throw new StateError('iteration not started');
    if (end < 0) throw new StateError('no more bindings');
    return text.substring(start + 2, end - 2);
  }

  bool moveNext() {
    if (end < 0) return false;

    previousEnd = end;
    start = text.indexOf('{{', end);
    if (start < 0) {
      end = -1;
      start = length;
      return false;
    }

    end = text.indexOf('}}', start);
    if (end < 0) {
      start = length;
      return false;
    }
    // For consistency, start and end both include the curly braces.
    end += 2;
    return true;
  }
}
