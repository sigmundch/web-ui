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
FileInfo analyzeNode(Node source, {bool cleanHtml: false}) {
  var result = new FileInfo();
  new _Analyzer(result).visit(source);
  if (cleanHtml) new _HtmlCleaner().visit(result);
  return result;
}

/** Extract relevant information from all files found from the root document. */
void analyzeFile(SourceFile file, Map<Path, FileInfo> info) {
  var fileInfo = info[file.path];
  _normalize(fileInfo, info);
  new _Analyzer(fileInfo).visit(file.document);
  new _HtmlCleaner().visit(fileInfo);
}

// TODO(jmesserly): see if we can drive this entirely off info, so it doesn't
// duplicate parsing elsewhere in analyzer.
/** Remove all MDV attributes; post-analysis these attributes are not needed. */
class _HtmlCleaner extends InfoVisitor {

  void visitElementInfo(ElementInfo info) {
    var node = info.node;
    if (info.isIterateOrIf) {
      // Remove children but not template node itself
      node.nodes.clear();

      // Hide all template elements. At the very least, we must do this for
      // template attributes, such as `<td template instantiate="if cond">`.
      // TODO(jmesserly): should probably inject a stylesheet into the page:
      // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/templates/index.html#css-additions
      node.attributes['style'] = 'display:none';
    }

    node.attributes.forEach((name, value) {
      visitAttribute(node, name, value);
    });

    if (info.contentBinding != null) {
      // TODO(jmesserly): this is hacky, see issue #133.
      for (var child in node.nodes) {
        if (child is Text) visitText(child);
      }
    }

    super.visitElementInfo(info);
  }

  // Remove text nodes with bindings.
  void visitText(Text text) {
    if (new BindingParser(text.value).moveNext()) {
      text.remove();
    }
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
        if (new BindingParser(value).moveNext()) {
          node.attributes.remove(name);
        }
    }
  }
}

/** A visitor that walks the HTML to extract all the relevant information. */
class _Analyzer extends TreeVisitor {
  final FileInfo _fileInfo;
  LibraryInfo _currentInfo;
  ElementInfo _parent;
  int _uniqueId = 0;

  _Analyzer(this._fileInfo) {
    _currentInfo = _fileInfo;
  }

  void visitElement(Element node) {
    var info = null;
    if (node.tagName == 'script') {
      // We already extracted script tags in previous phase.
      return;
    }

    // Bind to the parent element.
    if (node.tagName == 'template' || node.attributes.containsKey('template')) {
      // template tags are handled specially.
      info = _createTemplateInfo(node);
    }

    if (info == null) {
      info = new ElementInfo(node, _parent);
    }

    if (node.id != '') info.identifier = '_${toCamelCase(node.id)}';
    if (node.tagName == 'body') {
      // TODO(jmesserly): too much knowledge of codegen here.
      info.identifier = '_root';
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
      // TODO(jmesserly): don't create the info with a parent, and don't remove
      // the node until _HtmlCleaner.
      info.remove();
      info.node.remove();

      _bindExtends(component);

      _currentInfo = component;
    }

    var savedParent = _parent;
    _parent = info;

    // Invoke super to visit children.
    super.visitElement(node);
    _currentInfo = lastInfo;

    _parent = savedParent;

    if (_parent == null) {
      _fileInfo.bodyInfo = info;
    }

    if (info.needsIdentifier && info.identifier == null) {
      var id = '__e-$_uniqueId';
      info.identifier = toCamelCase(id);
      if (info.needsQuery) node.attributes['id'] = id;
      _uniqueId++;
    }
  }

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

  TemplateInfo _createTemplateInfo(Element node) {
    var instantiate = node.attributes['instantiate'];
    var iterate = node.attributes['iterate'];

    // Note: we issue warnings instead of errors because the spirit of HTML and
    // Dart is to be forgiving.
    if (instantiate != null && iterate != null) {
      messages.warning('<template> element cannot have iterate and instantiate '
          'attributes', node.span, file: _fileInfo.path);
      return null;
    }

    if (node.nodes.filter((n) => n is Element).length == 0) {
      // Ignore templates with no children
      // TODO(jmesserly): this is wrong when we want to support fragments
      return null;
    }

    if (instantiate != null) {
      if (instantiate.startsWith('if ')) {
        return new TemplateInfo(node, _parent,
            ifCondition: instantiate.substring(3));
      }

      // TODO(jmesserly): we need better support for <template instantiate>
      // as it exists in MDV. Right now we ignore it, but we provide support for
      // data binding everywhere.
      if (instantiate != '') {
        messages.warning('<template instantiate> must either have an empty '
          'attribute or be of the form <template instantiate="if condition">.',
          node.span, file: _fileInfo.path);
      }
    } else if (iterate != null) {
      var match = const RegExp(r"(.*) in (.*)").firstMatch(iterate);
      if (match != null) {
        return new TemplateInfo(node, _parent, loopVariable: match[1],
            loopItems: match[2]);
      }
      messages.warning('<template> iterate must be of the form: '
          'iterate="variable in list", where "variable" is your variable name '
          'and "list" is the list of items.',
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
    var info = new ElementInfo(text, _parent);

    var parser = new BindingParser(text.value);
    if (!parser.moveNext()) return;

    if (info.parent.contentBinding != null) {
      // This is issue #133.
      messages.error('multiple text bindings in a simple element are not yet '
          'supported', text.span, file: _fileInfo.path);
      return;
    }

    var parentElem = text.parent;
    info.parent.hasDataBinding = true;
    info.hasDataBinding = true;

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
 * a script tag with the 'src' attribute.
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
