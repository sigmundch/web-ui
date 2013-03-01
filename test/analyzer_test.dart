// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_test;

import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:logging/logging.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'package:web_ui/src/analyzer.dart';
import 'package:web_ui/src/file_system/path.dart';
import 'package:web_ui/src/files.dart';
import 'package:web_ui/src/info.dart';
import 'package:web_ui/src/messages.dart';
import 'package:web_ui/src/summary.dart';
import 'package:web_ui/src/utils.dart';
import 'testing.dart';
import 'testing.dart' as testing;

main() {
  useCompactVMConfiguration();

  // the mock messages
  var messages;

  analyzeElement(elem) => testing.analyzeElement(elem, messages);

  analyzeDefinitionsInTree(doc) =>
      testing.analyzeDefinitionsInTree(doc, messages);

  analyzeFiles(files) => testing.analyzeFiles(files, messages: messages);

  group("", () {
    setUp(() {
      messages = new Messages.silent();
    });

    test('parse single element', () {
      var input = '<div></div>';
      var elem = parseSubtree(input);
      expect(elem.outerHtml, input);
    });

    test('id extracted - shallow element', () {
      var input = '<div id="foo"></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.node.id, equals('foo'));
      expect(info.identifier, equals('__foo'));
    });

    test('id extracted - deep element', () {
      var input = '<div><div><div id="foo"></div></div></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.identifier, isNull);
      expect(info.children[0].identifier, isNull);
      expect(info.children[0].children[0].identifier, equals('__foo'));
    });

    test('ElementInfo.toString()', () {
      var input = '<div id="foo"></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.toString().startsWith('#<ElementInfo '), true);
    });

    test('id as identifier - found in dom', () {
      var input = '<div id="foo-bar"></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.identifier, equals('__fooBar'));
    });

    test('id as identifier - many id names', () {
      identifierOf(String id) {
        var input = '<div id="$id"></div>';
        var info = analyzeElement(parseSubtree(input));
        return info.identifier;
      }
      expect(identifierOf('foo-bar'), equals('__fooBar'));
      expect(identifierOf('foo-b'), equals('__fooB'));
      expect(identifierOf('foo-'), equals('__foo'));
      expect(identifierOf('foo--bar'), equals('__fooBar'));
      expect(identifierOf('foo--bar---z'), equals('__fooBarZ'));
    });

    test('id as identifier - deep element', () {
      var input = '<div><div><div id="foo-ba"></div></div></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.children[0].children[0].identifier, equals('__fooBa'));
    });

    test('id as identifier - no id', () {
      var input = '<div></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.identifier, isNull);
    });

    test('hasDataBinding - attribute w/o data', () {
      var input = '<input value="x">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.hasDataBinding, false);
    });

    test('hasDataBinding - attribute with data, 1 way binding', () {
      var input = '<input value="{{x}}">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.hasDataBinding, true);
    });

    test('hasDataBinding - attribute with data, 2 way binding', () {
      var input = '<input bind-value="x">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.hasDataBinding, true);
      expect(messages.length, 0);
    });

    test('hasDataBinding - attribute with data, 2 way binding', () {
      var input = '<input bind-value-as-date="x">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.hasDataBinding, true);
      expect(messages.length, 0);
    });

    test('hasDataBinding - attribute with data, 2 way binding', () {
      var input = '<input bind-value-as-number="x">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.hasDataBinding, true);
      expect(messages.length, 0);
    });

    test('hasDataBinding - content with data', () {
      var input = '<div>{{x}}</div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.hasDataBinding, true);
      expect(info.node.nodes.length, 1);
      var textInfo = info.children[0];
      expect(textInfo.binding.exp, 'x');
      expect(textInfo.binding.isFinal, false);
      expect(textInfo.node.value, '');
    });

    test('hasDataBinding - content with data, one time binding', () {
      var input = '<div>{{x | final}}</div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.hasDataBinding, true);
      expect(info.node.nodes.length, 1);
      var textInfo = info.children[0];
      expect(textInfo.binding.exp, 'x');
      expect(textInfo.binding.isFinal, true);
      expect(textInfo.node.value, '');
    });

    test('hasDataBinding - content with text and data', () {
      var input = '<div> a b {{x}}c</div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.node.nodes.length, 1);
      expect(info.node.nodes[0].value, ' a b {{x}}c');
      expect(info.hasDataBinding, true);

      expect(info.children.length, 3);
      expect(info.children[0].node.value, ' a b ');
      expect(info.children[1].node.value, '');
      expect(info.children[1].binding.exp, 'x');
      expect(info.children[2].node.value, 'c');
    });

    test('attribute - no info', () {
      var input = '<input value="x">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes, isNotNull);
      expect(info.attributes, isEmpty);
    });

    test('attribute - 1 way binding input value', () {
      var input = '<input value="{{x}}">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['value'], isNotNull);
      expect(info.attributes['value'].isSimple, true);
      expect(info.attributes['value'].bindings.map((b) => b.exp),
          equals(['x']));
      expect(info.attributes['value'].textContent, isNull);
      expect(info.events, isEmpty);
    });

    test('attribute - 1 way binding data-hi', () {
      var input = '<div data-hi="{{x}}">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['data-hi'], isNotNull);
      expect(info.attributes['data-hi'].isSimple, true);
      expect(info.attributes['data-hi'].bindings.map((b) => b.exp),
          equals(['x']));
      expect(info.attributes['data-hi'].textContent, isNull);
      expect(info.events, isEmpty);
    });

    test('attribute - single binding with text', () {
      var input = '<input value="foo {{x}} bar">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['value'], isNotNull);
      expect(info.attributes['value'].isText, true);
      expect(info.attributes['value'].bindings.map((b) => b.exp),
          equals(['x']));
      expect(info.attributes['value'].textContent, equals(['foo ', ' bar']));
      expect(info.events, isEmpty);
    });

    test('attribute - multiple bindings with text', () {
      var input = '<input value="a{{x}}b{{y}}">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['value'], isNotNull);
      expect(info.attributes['value'].isText, true);
      expect(info.attributes['value'].bindings.map((b) => b.exp),
          equals(['x', 'y']));
      expect(info.attributes['value'].textContent, equals(['a', 'b', '']));
      expect(info.events, isEmpty);
    });

    test('attribute - 2 way binding input value', () {
      var input = '<input bind-value="x">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['value'], isNotNull);
      expect(info.attributes['value'].isSimple, true);
      expect(info.attributes['value'].bindings.map((b) => b.exp),
          equals(['x']));
      expect(info.events.keys, equals(['onInput']));
      expect(info.events['onInput'].length, equals(1));
      expect(info.events['onInput'][0].action('foo'), equals('x = foo.value'));
    });

    test('attribute - 2 way binding textarea value', () {
      var input = '<textarea bind-value="x">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['value'], isNotNull);
      expect(info.attributes['value'].isSimple, true);
      expect(info.attributes['value'].boundValue, equals('x'));
      expect(info.events.keys, equals(['onInput']));
      expect(info.events['onInput'].length, equals(1));
      expect(info.events['onInput'][0].action('foo'), equals('x = foo.value'));
    });

    test('attribute - 2 way binding select', () {
      var input = '<select bind-selected-index="x" bind-value="y">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.keys, equals(['selectedIndex', 'value']));
      expect(info.attributes['selectedIndex'], isNotNull);
      expect(info.attributes['selectedIndex'].isSimple, true);
      expect(info.attributes['selectedIndex'].bindings.map((b) => b.exp),
          equals(['x']));
      expect(info.attributes['value'], isNotNull);
      expect(info.attributes['value'].isSimple, true);
      expect(info.attributes['value'].bindings.map((b) => b.exp),
          equals(['y']));
      expect(info.events.keys, equals(['onChange']));
      expect(info.events['onChange'].length, equals(2));
      expect(info.events['onChange'][0].action('foo'),
          equals('x = foo.selectedIndex'));
      expect(info.events['onChange'][1].action('foo'), equals('y = foo.value'));
    });

    test('attribute - 1 way binding checkbox', () {
      var input = '<input type="checkbox" checked="{{x}}">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['checked'], isNotNull);
      expect(info.attributes['checked'].isSimple, true);
      expect(info.attributes['checked'].boundValue, equals('x'));
      expect(info.events, isEmpty);
    });

    test('attribute - 2 way binding checkbox - invalid', () {
      var node = parseSubtree('<input bind-checked="x">');
      var info = analyzeElement(node);
      expect(info.attributes.length, equals(0));
      expect(messages.length, 1);
      expect(messages[0].message, contains('type="radio" or type="checked"'));
      expect(messages[0].span, equals(node.sourceSpan));
    });

    test('attribute - 2 way binding checkbox', () {
      var input = '<input type="checkbox" bind-checked="x">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['checked'], isNotNull);
      expect(info.attributes['checked'].isSimple, true);
      expect(info.attributes['checked'].boundValue, equals('x'));
      expect(info.events.keys, equals(['onChange']));
      expect(info.events['onChange'].length, equals(1));
      expect(info.events['onChange'][0].action('foo'),
          equals('x = foo.checked'));
    });

    test('attribute - 1 way binding, normal field', () {
      var input = '<div foo="{{x}}"></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['foo'], isNotNull);
      expect(info.attributes['foo'].isSimple, true);
      expect(info.attributes['foo'].boundValue, equals('x'));
    });

    test('attribute - single class', () {
      var input = '<div class="{{x}}"></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['class'], isNotNull);
      expect(info.attributes['class'].isClass, true);
      expect(info.attributes['class'].bindings.map((b) => b.exp),
          equals(['x']));
    });

    test('attribute - many classes', () {
      var input = '<div class="{{x}} {{y}}{{z}}  {{w}}"></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['class'], isNotNull);
      expect(info.attributes['class'].isClass, true);
      expect(info.attributes['class'].bindings.map((b) => b.exp),
          equals(['x', 'y', 'z', 'w']));
    });

    test('attribute - many classes 2', () {
      var input =
          '<div class="class1 {{x}} class2 {{y}}{{z}} {{w}} class3 class4">'
          '</div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['class'], isNotNull);
      expect(info.attributes['class'].isClass, true);
      expect(info.attributes['class'].bindings.map((b) => b.exp),
          equals(['x', 'y', 'z', 'w']));
      expect(info.node.attributes['class'].length, 30);
      expect(info.node.attributes['class'].contains('class1'), true);
      expect(info.node.attributes['class'].contains('class2'), true);
      expect(info.node.attributes['class'].contains('class3'), true);
      expect(info.node.attributes['class'].contains('class4'), true);
    });

    test('attribute - single style', () {
      var input = '<div style="{{x}}"></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['style'], isNotNull);
      expect(info.attributes['style'].isStyle, true);
      expect(info.attributes['style'].bindings.map((b) => b.exp),
          equals(['x']));
      expect(messages.length, 0);
    });

    test('attribute - several style properties', () {
      var input = '<div style="display: {{x}}"></div>';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes.length, equals(1));
      expect(info.attributes['style'], isNotNull);
      // Until we can parse CSS attributes, we are not do smart binding for
      // style properties. We use text bindings instead.
      expect(info.attributes['style'].isStyle, false);
      expect(info.attributes['style'].isText, true);
      expect(info.attributes['style'].bindings.map((b) => b.exp),
          equals(['x']));
      expect(info.attributes['style'].textContent, equals(['display: ', '']));
      expect(messages.length, 0);
    });

    test('attribute - event hookup with on-', () {
      var input = '<input on-double-click="foo">';
      var info = analyzeElement(parseSubtree(input));
      expect(info.attributes, isEmpty);
      expect(info.events.keys, equals(['onDoubleClick']));
      var events = info.events['onDoubleClick'];
      expect(events.length, equals(1));
      expect(events[0].streamName, 'onDoubleClick');
      expect(events[0].action('bar'), 'foo');
      expect(messages.length, 0);
    });

    test('attribute - warning for JavaScript inline handler', () {
      var node = parseSubtree('<input onclick="foo">');
      var info = analyzeElement(node);
      expect(info.attributes, isEmpty);
      expect(info.events.keys, equals([]));
      expect(messages.length, 1);
      expect(messages[0].message,
          contains('inline JavaScript event handler'));
      expect(messages[0].span, equals(node.sourceSpan));
    });

    test('template element', () {
      var info = analyzeElement(parseSubtree('<template></template>'));
      expect(info, isNot(new isInstanceOf<TemplateInfo>('TemplateInfo')),
          reason: 'example does not need TemplateInfo');
    });

    // TODO(jmesserly): I'm not sure we are implementing correct behavior for
    // `<template instantiate>` in Model-Driven-Views.
    test('template instantiate (invalid)', () {
      var elem = parseSubtree('<template instantiate="foo"></template>');
      var info = analyzeElement(elem);

      expect(elem.attributes, equals({'instantiate': 'foo'}));
      expect(info, isNot(new isInstanceOf<TemplateInfo>('TemplateInfo')),
          reason: 'example is not a valid template');
    });

    test('template if (empty)', () {
      var elem = parseSubtree('<template if="foo"></template>');
      var info = analyzeElement(elem);
      expect(info.hasIfCondition, false);
    });

    test('template if', () {
      var elem = parseSubtree('<template if="foo"><div>');
      var div = elem.query('div');
      TemplateInfo info = analyzeElement(elem);
      expect(info.hasIfCondition, true);
      expect(info.createdInCode, false);
      expect(info.children[0].node, equals(div));
      expect(info.children[0].createdInCode, true);
      expect(div.id, '');
      expect(elem.attributes, equals({'if': 'foo', 'id': '__e-0'}));
      expect(info.ifCondition, equals('foo'));
      expect(info.hasIterate, isFalse);
      expect(messages.length, 0);
    });

    test('template instantiate if', () {
      var elem = parseSubtree('<template instantiate="if foo"><div>');
      var div = elem.query('div');
      TemplateInfo info = analyzeElement(elem);
      expect(info.hasIfCondition, true);
      expect(info.createdInCode, false);
      expect(info.children[0].node, equals(div));
      expect(info.children[0].createdInCode, true);
      expect(div.id, '');
      expect(elem.attributes, equals({'instantiate': 'if foo', 'id': '__e-0'}));
      expect(info.ifCondition, equals('foo'));
      expect(info.hasIterate, isFalse);
      expect(messages.length, 0);
    });

    test('if w/o template has warning', () {
      var elem = parseSubtree('<div if="foo">');
      analyzeElement(elem);
      expect(messages.length, 1);
      expect(messages[0].message, contains('template attribute is required'));
      expect(messages[0].span, equals(elem.sourceSpan));
    });

    test('instantiate-if w/o template has warning', () {
      var elem = parseSubtree('<div instantiate="if foo">');
      analyzeElement(elem);
      expect(messages.length, 1);
      expect(messages[0].message, contains('template attribute is required'));
      expect(messages[0].span, equals(elem.sourceSpan));
    });

    test('template iterate (invalid)', () {
      var elem = parseSubtree(
          '<template iterate="bar" is="x-list"></template>');
      var info = analyzeElement(elem);

      expect(elem.attributes, equals({'iterate': 'bar', 'is': 'x-list'}));
      expect(info, isNot(new isInstanceOf<TemplateInfo>('TemplateInfo')),
        reason: 'example is not a valid template');
    });

    test('template iterate', () {
      var elem = parseSubtree(
          '<template iterate="foo in bar" is="x-list"><div>');
      TemplateInfo info = analyzeElement(elem);
      var div = elem.query('div');
      expect(info.createdInCode, false);
      expect(info.children[0].node, equals(div));
      expect(info.children[0].createdInCode, true);
      expect(div.id, '');
      expect(elem.attributes, equals({
          'iterate': 'foo in bar', 'is': 'x-list', 'id': '__e-0'}));
      expect(info.ifCondition, isNull);
      expect(info.loopVariable, equals('foo'));
      expect(info.loopItems, equals('bar'));
    });

    test('component is="" not found - warning', () {
      var elem = parseSubtree('<li is="x-todo-row"></li>');
      var info = analyzeElement(elem);
      expect(messages.length, 1);
      expect(messages[0].message, contains('x-todo-row not found'));
      expect(messages[0].span, equals(elem.sourceSpan));
    });

    test('component custom tag not found - warning', () {
      var elem = parseSubtree('<x-todo-row></x-todo-row>');
      var info = analyzeElement(elem);
      expect(messages.length, 1);
      expect(messages[0].message, contains('x-todo-row not found'));
      expect(messages[0].span, equals(elem.sourceSpan));
    });

    test('extends not found - warning', () {
      var files = parseFiles({
        'index.html': '<body><element name="x-quux3" extends="x-foo" '
                                     'constructor="Bar"><template>'
      });
      var fileInfo = analyzeFiles(files);
      var elem = fileInfo['index.html'].bodyInfo.node.query('element');
      expect(messages.length, 1);
      expect(messages[0].message, contains('x-foo not found'));
      expect(messages[0].span, equals(elem.sourceSpan));
    });

    test('component properties 1-way binding', () {
      var files = parseFiles({
        'index.html': '<head><link rel="components" href="foo.html">'
                      '<body><element name="x-bar" extends="x-foo" '
                                     'constructor="Bar"></element>'
                      '<x-bar quux="{{123}}">',
        'foo.html': '<body><element name="x-foo" constructor="Foo">'
      });

      var fileInfo = analyzeFiles(files);
      var bar = fileInfo['index.html'].query('x-bar');
      expect(bar.hasDataBinding, true);
      expect(bar.attributes.keys, ['quux']);
      expect(bar.attributes['quux'].customTwoWayBinding, false);
      expect(bar.attributes['quux'].boundValue, '123');
    });

    test('component properties 2-way binding', () {
      var files = parseFiles({
        'index.html': '<head><link rel="components" href="foo.html">'
                      '<body><element name="x-bar" extends="x-foo" '
                                     'constructor="Bar"></element>'
                      '<x-bar bind-quux="assignable">',
        'foo.html': '<body><element name="x-foo" constructor="Foo">'
      });

      var fileInfo = analyzeFiles(files)['index.html'];
      var bar = fileInfo.query('x-bar');
      expect(bar.component, same(fileInfo.declaredComponents[0]));
      expect(bar.hasDataBinding, true);
      expect(bar.attributes.keys, ['quux']);
      expect(bar.attributes['quux'].customTwoWayBinding, true);
      expect(bar.attributes['quux'].boundValue, 'assignable');
    });
  });

  group('analyzeDefinitions', () {
    setUp(() {
      messages = new Messages.silent();
    });

    test('links', () {
      var info = analyzeDefinitionsInTree(parse(
        '<head>'
          '<link rel="components" href="foo.html">'
          '<link rel="something" href="bar.html">'
          '<link rel="components" hrefzzz="baz.html">'
          '<link rel="components" href="quux.html">'
        '</head>'
        '<body><link rel="components" href="quuux.html">'
      ));
      expect(info.componentLinks, equals([
          new Path('foo.html'), new Path('quux.html')]));
    });

    test('elements', () {
      var doc = parse(
        '<body>'
          '<element name="x-foo" constructor="Foo"></element>'
          '<element name="x-bar" constructor="Bar42"></element>'
        '</body>'
      );
      var foo = doc.body.queryAll('element')[0];
      var bar = doc.body.queryAll('element')[1];

      var info = analyzeDefinitionsInTree(doc);
      expect(info.declaredComponents.length, equals(2));

      var compInfo = info.declaredComponents[0];
      expect(compInfo.tagName, equals('x-foo'));
      expect(compInfo.className, equals('Foo'));
      expect(compInfo.element, equals(foo));
      expect(compInfo.hasConflict, isFalse);

      compInfo = info.declaredComponents[1];
      expect(compInfo.tagName, equals('x-bar'));
      expect(compInfo.className, equals('Bar42'));
      expect(compInfo.element, equals(bar));
      expect(compInfo.hasConflict, isFalse);
    });

    test('element without extends defaults to span', () {
      var doc = parse('<body><element name="x-baz"><template>');
      var info = analyzeDefinitionsInTree(doc);
      expect(messages.length, 0);
      expect(info.declaredComponents.length, equals(1));
      expect(info.declaredComponents[0].extendsTag, equals('span'));
    });

    test('element without constructor', () {
      var doc = parse(
        '<body>'
          '<element name="x-baz"></element>'
          '<element name="my-quux"></element>'
        '</body>'
      );
      var info = analyzeDefinitionsInTree(doc);
      expect(info.declaredComponents.length, equals(2));
      expect(info.declaredComponents[0].className, equals('Baz'));
      expect(info.declaredComponents[1].className, equals('MyQuux'));
    });

    test('invalid element without tag name', () {
      var doc = parse('<body><element constructor="Baz"></element>');
      var info = analyzeDefinitionsInTree(doc);
      expect(info.declaredComponents.length, equals(0));
      // TODO(jmesserly): validate warnings
    });

    test('duplicate tag name - is error', () {
      var doc = parse(
        '<body>'
          '<element name="x-quux" constructor="Quux"></element>'
          '<element name="x-quux" constructor="Quux2"></element>'
        '</body>'
      );
      var srcFile = new SourceFile(new Path('main.html'))..document = doc;
      var info = analyzeDefinitions(srcFile, messages);
      expect(info.declaredComponents.length, equals(2));

      // no conflicts yet.
      expect(info.declaredComponents[0].hasConflict, isFalse);
      expect(info.declaredComponents[1].hasConflict, isFalse);

      var quuxElement = doc.query('element');
      expect(quuxElement, isNotNull);
      analyzeFile(srcFile, toPathMap({'main.html': info }), new IntIterator(),
          messages);

      expect(info.components.length, equals(1));
      var compInfo = info.components['x-quux'];
      expect(compInfo.hasConflict, true);
      expect(compInfo.tagName, equals('x-quux'));
      expect(compInfo.className, equals('Quux'));
      expect(compInfo.element, equals(quuxElement));
    });

    test('duplicate constructor name - is valid', () {
      var doc = parse(
        '<body>'
          '<element name="x-quux" constructor="Quux"></element>'
          '<element name="x-quux2" constructor="Quux"></element>'
        '</body>'
      );
      var info = analyzeDefinitionsInTree(doc);

      var quux = doc.body.queryAll('element')[0];
      var quux2 = doc.body.queryAll('element')[1];

      expect(info.declaredComponents.length, equals(2));

      var compInfo = info.declaredComponents[0];
      expect(compInfo.tagName, equals('x-quux'));
      expect(compInfo.className, equals('Quux'));
      expect(compInfo.element, equals(quux));
      expect(compInfo.hasConflict, isFalse);

      compInfo = info.declaredComponents[1];
      expect(compInfo.tagName, equals('x-quux2'));
      expect(compInfo.className, equals('Quux'));
      expect(compInfo.element, equals(quux2));
      expect(compInfo.hasConflict, isFalse);
    });

    test('inline script without type - no warning', () {
      var doc = parse('<body><script>foo</script></body>');
      analyzeDefinitionsInTree(doc);
      expect(messages.warnings.length, 0);
    });

    test('inline script without type in component - warning', () {
      var doc = parse(
        '<body>'
          '<element name="x-quux">'
            '<template></template><script>foo</script>'
          '</element>'
        '</body>'
      );
      analyzeDefinitionsInTree(doc);
      expect(messages.warnings.length, 1);
      expect(messages[0].message, contains(
          'Did you forget type="application/dart"'));
    });

    test('inline script with non-dart type in component - warning', () {
      var doc = parse(
        '<body>'
          '<element name="x-quux">'
            '<template></template><script type="text/foo">foo</script>'
          '</element>'
        '</body>'
      );
      analyzeDefinitionsInTree(doc);
      expect(messages.warnings.length, 1);
      expect(messages[0].message, contains(
          'https://github.com/dart-lang/web-ui/issues/340'));
    });

    test('script src="a.darr" without type - no warning', () {
      var doc = parse('<body><script src="a.darr"></script></body>');
      analyzeDefinitionsInTree(doc);
      expect(messages.length, 0);
    });

    test('script src="a.dart" without type - warning', () {
      var doc = parse('<body><script src="a.dart"></script></body>');
      analyzeDefinitionsInTree(doc);
      expect(messages.warnings.length, 1);
      expect(messages[0].message, contains(
          'Did you forget type="application/dart"'));
    });

    test('script element with illegal suffix - accept with warning', () {
      var doc = parse(
        '<body>'
          '<script type="application/dart" src="a.darr"></script>'
        '</body>'
      );
      var info = analyzeDefinitionsInTree(doc);
      expect(messages.warnings.length, 1);
      expect(messages[0].message,
          contains("scripts should use the .dart file extension"));
    });

    test('script element with relative path - accept', () {
      var doc = parse(
        '<body>'
          '<script type="application/dart" src="a.dart"></script>'
        '</body>'
      );
      var info = analyzeDefinitionsInTree(doc);
      expect(messages.length, 0);
    });

    test('script element with absolute path - accept with error', () {
      var doc = parse(
        '<body>'
          '<script type="application/dart" src="/a.dart"></script>'
        '</body>'
      );
      var info = analyzeDefinitionsInTree(doc);
      expect(messages.errors.length, 1);
      expect(messages[0].message,
          contains("script tag should not use absolute path"));
    });

    test("script element with 'src' and content - accept with error", () {
      var doc = parse(
        '<body>'
          '<script type="application/dart" src="a.dart">main(){}</script>'
        '</body>'
      );
      var info = analyzeDefinitionsInTree(doc);
      expect(messages.errors.length, 1);
      expect(messages[0].message,
          contains('script tag has "src" attribute and also has script text'));
    });
  });

  group('analyzeFile', () {
    setUp(() {
      messages = new Messages.silent();
    });

    test('binds components in same file', () {
      var doc = parse('<body><x-foo><element name="x-foo" constructor="Foo">');
      var srcFile = new SourceFile(new Path('main.html'))..document = doc;
      var info = analyzeDefinitions(srcFile, messages);
      expect(info.declaredComponents.length, equals(1));

      analyzeFile(srcFile, toPathMap({ 'main.html': info }), new IntIterator(),
          messages);
      expect(info.components.keys, equals(['x-foo']));
      expect(info.query('x-foo').component, equals(info.declaredComponents[0]));
    });

    test('binds components from another file', () {
      var files = parseFiles({
        'index.html': '<head><link rel="components" href="foo.html">'
                      '<body><x-foo>',
        'foo.html': '<body><element name="x-foo" constructor="Foo">'
      });

      var fileInfo = analyzeFiles(files);

      var info = fileInfo['index.html'];
      expect(info.declaredComponents.length, isZero);
      expect(info.components.keys, equals(['x-foo']));
      var compInfo = fileInfo['foo.html'].declaredComponents[0];
      _compareSummary(info.query('x-foo').component, compInfo);
    });

    test('ignores elements with multiple definitions', () {
      var files = parseFiles({
        'index.html': '<head>'
                      '<link rel="components" href="foo.html">'
                      '<link rel="components" href="bar.html">'
                      '<body><x-foo>',
        'foo.html': '<body><element name="x-foo" constructor="Foo">',
        'bar.html': '<body><element name="x-foo" constructor="Foo">'
      });

      var fileInfo = analyzeFiles(files);

      var info = fileInfo['index.html'];
      expect(info.components.keys, equals(['x-foo']));

      var compInfo = fileInfo['foo.html'].declaredComponents[0];
      // Now that each file is analyzed separately, hasConflict is tracked on a
      // ComponentSummary that represents compInfo, but it's not the same
      // object.
      expect(compInfo.hasConflict, false);
      expect(info.query('x-foo').component, isNull);
    });

    test('shadowing of imported names is allowed', () {
      var files = parseFiles({
        'index.html': '<head><link rel="components" href="foo.html">'
                      '<body><x-foo>',
        'foo.html': '<head><link rel="components" href="bar.html">'
                    '<body><element name="x-foo" constructor="Foo">',
        'bar.html': '<body><element name="x-foo" constructor="Foo">'
      });

      var fileInfo = analyzeFiles(files);

      var info = fileInfo['index.html'];
      expect(info.components.keys, equals(['x-foo']));

      var compInfo = fileInfo['foo.html'].declaredComponents[0];
      _compareSummary(info.query('x-foo').component, compInfo);
    });

    test('element imports are not transitive', () {
      var files = parseFiles({
        'index.html': '<head><link rel="components" href="foo.html">'
                      '<body><x-foo>',
        'foo.html': '<head><link rel="components" href="bar.html">',
        'bar.html': '<body><element name="x-foo" constructor="Foo">'
      });

      var fileInfo = analyzeFiles(files);

      var info = fileInfo['index.html'];
      expect(info.components.keys, equals([]));

      expect(fileInfo['foo.html'].declaredComponents.length, isZero);
      expect(info.query('x-foo').component, isNull);
    });

    test('invalid elements - no name, with body', () {
      var doc = parse(
        '<body>'
          '<element name="x-1" constructor="M1"><template></template></element>'
          '<element constructor="M2">'
            '<template><x-1></x-1></template>'
          '</element>'
          '<element name="x-3">' // missing constructor
            '<template><x-1></x-1></template>'
          '</element>'
        '</body>'
      );

      var srcFile = new SourceFile(new Path('main.html'))..document = doc;
      var info = analyzeDefinitions(srcFile, messages);
      analyzeFile(srcFile, toPathMap({ 'main.html': info }), new IntIterator(),
          messages);
    });

    test('components extends another component', () {
      var files = parseFiles({
        'index.html': '<head><link rel="components" href="foo.html">'
                      '<body><element name="x-bar" extends="x-foo" '
                                     'constructor="Bar">',
        'foo.html': '<body><element name="x-foo" constructor="Foo">'
      });

      var fileInfo = analyzeFiles(files);

      var info = fileInfo['index.html'];
      expect(info.components.keys, equals(['x-bar', 'x-foo']));
      expect(info.components['x-bar'].extendsComponent,
          equals(info.components['x-foo']));
    });

    test('recursive component import', () {
      var files = parseFiles({
        'index.html': '<head>'
                      '<link rel="components" href="foo.html">'
                      '<link rel="components" href="bar.html">'
                      '<body><x-foo><x-bar>',
        'foo.html': '<head><link rel="components" href="bar.html">'
                    '<body><element name="x-foo" constructor="Foo">',
        'bar.html': '<head><link rel="components" href="foo.html">'
                    '<body><element name="x-bar" constructor="Boo">'
      });

      var fileInfo = analyzeFiles(files);
      var info = fileInfo['index.html'];
      expect(info.components.keys, equals(['x-bar', 'x-foo']));

      var compInfo = fileInfo['foo.html'].declaredComponents[0];
      _compareSummary(info.query('x-foo').component, compInfo);
      compInfo = fileInfo['bar.html'].declaredComponents[0];
      _compareSummary(info.query('x-bar').component, compInfo);
    });
  });
}

_compareSummary(ComponentSummary summary, ComponentSummary other) {
  if (summary == null) {
    expect(other, isNull);
    return;
  }
  expect(summary.inputPath, equals(other.inputPath));
  expect(summary.outputFilename, equals(other.outputFilename));
  expect(summary.tagName, equals(other.tagName));
  expect(summary.extendsTag, equals(other.extendsTag));
  _compareSummary(summary.extendsComponent, other.extendsComponent);
  expect(summary.className, equals(other.className));
}
