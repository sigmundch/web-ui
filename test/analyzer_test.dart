// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_test;

import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:web_components/src/analyzer.dart';
import 'package:web_components/src/info.dart';
import 'package:web_components/src/files.dart';
import 'package:web_components/src/file_system/path.dart';
import 'testing.dart';

main() {
  useVmConfiguration();
  useMockMessages();

  test('parse single element', () {
    var input = '<div></div>';
    var elem = parseSubtree(input);
    expect(elem.outerHTML, input);
  });

  test('id extracted - shallow element', () {
    var input = '<div id="foo"></div>';
    var info = analyzeElement(parseSubtree(input));
    expect(info.node.id, equals('foo'));
    expect(info.identifier, equals('_foo'));
  });

  test('id extracted - deep element', () {
    var input = '<div><div><div id="foo"></div></div></div>';
    var info = analyzeElement(parseSubtree(input));
    expect(info.identifier, isNull);
    expect(info.children[0].identifier, isNull);
    expect(info.children[0].children[0].identifier, equals('_foo'));
  });

  test('ElementInfo.toString()', () {
    var input = '<div id="foo"></div>';
    var info = analyzeElement(parseSubtree(input));
    expect(info.toString().startsWith('#<ElementInfo '), true);
  });

  test('id as identifier - found in dom', () {
    var input = '<div id="foo-bar"></div>';
    var info = analyzeElement(parseSubtree(input));
    expect(info.identifier, equals('_fooBar'));
  });

  test('id as identifier - many id names', () {
    identifierOf(String id) {
      var input = '<div id="$id"></div>';
      var info = analyzeElement(parseSubtree(input));
      return info.identifier;
    }
    expect(identifierOf('foo-bar'), equals('_fooBar'));
    expect(identifierOf('foo-b'), equals('_fooB'));
    expect(identifierOf('foo-'), equals('_foo'));
    expect(identifierOf('foo--bar'), equals('_fooBar'));
    expect(identifierOf('foo--bar---z'), equals('_fooBarZ'));
  });

  test('id as identifier - deep element', () {
    var input = '<div><div><div id="foo-ba"></div></div></div>';
    var info = analyzeElement(parseSubtree(input));
    expect(info.children[0].children[0].identifier, equals('_fooBa'));
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
    var input = '<input data-bind="value:x">';
    var info = analyzeElement(parseSubtree(input));
    expect(info.hasDataBinding, true);
  });

  test('hasDataBinding - content with data', () {
    var input = '<div>{{x}}</div>';
    var info = analyzeElement(parseSubtree(input));
    expect(info.hasDataBinding, true);
    expect(info.node.nodes.length, 1);
    var textInfo = info.children[0];
    expect(textInfo.binding, 'x');
    expect(textInfo.node, same(info.node.nodes[0]));
  });

  test('hasDataBinding - content with text and data', () {
    var input = '<div> a b {{x}}c</div>';
    var info = analyzeElement(parseSubtree(input));
    expect(info.node.nodes.length, 3);
    expect(info.node.nodes[0].value, ' a b ');
    expect(info.node.nodes[1].value, '');
    expect(info.node.nodes[2].value, 'c');
    expect(info.hasDataBinding, true);

    var textInfo = info.children[1];
    expect(textInfo.node, same(info.node.nodes[1]));
    expect(textInfo.binding, 'x');
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
    expect(info.attributes['value'].bindings, equals(['x']));
    expect(info.attributes['value'].textContent, isNull);
    expect(info.events, isEmpty);
  });

  test('attribute - 1 way binding data-hi', () {
    var input = '<div data-hi="{{x}}">';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes.length, equals(1));
    expect(info.attributes['data-hi'], isNotNull);
    expect(info.attributes['data-hi'].isSimple, true);
    expect(info.attributes['data-hi'].bindings, equals(['x']));
    expect(info.attributes['data-hi'].textContent, isNull);
    expect(info.events, isEmpty);
  });

  test('attribute - single binding with text', () {
    var input = '<input value="foo {{x}} bar">';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes.length, equals(1));
    expect(info.attributes['value'], isNotNull);
    expect(info.attributes['value'].isText, true);
    expect(info.attributes['value'].bindings, equals(['x']));
    expect(info.attributes['value'].textContent, equals(['foo ', ' bar']));
    expect(info.events, isEmpty);
  });

  test('attribute - multiple bindings with text', () {
    var input = '<input value="a{{x}}b{{y}}">';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes.length, equals(1));
    expect(info.attributes['value'], isNotNull);
    expect(info.attributes['value'].isText, true);
    expect(info.attributes['value'].bindings, equals(['x', 'y']));
    expect(info.attributes['value'].textContent, equals(['a', 'b', '']));
    expect(info.events, isEmpty);
  });

  test('attribute - 2 way binding input value', () {
    var input = '<input data-bind="value:x">';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes.length, equals(1));
    expect(info.attributes['value'], isNotNull);
    expect(info.attributes['value'].isSimple, true);
    expect(info.attributes['value'].bindings, equals(['x']));
    expect(info.events.keys, equals(['input']));
    expect(info.events['input'].length, equals(1));
    expect(info.events['input'][0].action('foo', 'e'),
        equals('x = foo.value'));
  });

  test('attribute - 2 way binding textarea value', () {
    var input = '<textarea data-bind="value:x">';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes.length, equals(1));
    expect(info.attributes['value'], isNotNull);
    expect(info.attributes['value'].isSimple, true);
    expect(info.attributes['value'].boundValue, equals('x'));
    expect(info.events.keys, equals(['input']));
    expect(info.events['input'].length, equals(1));
    expect(info.events['input'][0].action('foo', 'e'),
        equals('x = foo.value'));
  });

  test('attribute - 2 way binding select', () {
    var input = '<select data-bind="selectedIndex:x,value:y">';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes.keys, equals(['selectedIndex', 'value']));
    expect(info.attributes['selectedIndex'], isNotNull);
    expect(info.attributes['selectedIndex'].isSimple, true);
    expect(info.attributes['selectedIndex'].bindings, equals(['x']));
    expect(info.attributes['value'], isNotNull);
    expect(info.attributes['value'].isSimple, true);
    expect(info.attributes['value'].bindings, equals(['y']));
    expect(info.events.keys, equals(['change']));
    expect(info.events['change'].length, equals(2));
    expect(info.events['change'][0].action('foo', 'e'),
        equals('x = foo.selectedIndex'));
    expect(info.events['change'][1].action('foo', 'e'),
        equals('y = foo.value'));
  });

  test('attribute - 1 way binding checkbox', () {
    var input = '<input checked="{{x}}">';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes.length, equals(1));
    expect(info.attributes['checked'], isNotNull);
    expect(info.attributes['checked'].isSimple, true);
    expect(info.attributes['checked'].boundValue, equals('x'));
    expect(info.events, isEmpty);
  });

  test('attribute - 2 way binding checkbox', () {
    var input = '<input data-bind="checked:x">';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes.length, equals(1));
    expect(info.attributes['checked'], isNotNull);
    expect(info.attributes['checked'].isSimple, true);
    expect(info.attributes['checked'].boundValue, equals('x'));
    expect(info.events.keys, equals(['click']));
    expect(info.events['click'].length, equals(1));
    expect(info.events['click'][0].action('foo', 'e'),
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
    expect(info.attributes['class'].bindings, equals(['x']));
  });

  test('attribute - many classes', () {
    var input = '<div class="{{x}} {{y}}{{z}}  {{w}}"></div>';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes.length, equals(1));
    expect(info.attributes['class'], isNotNull);
    expect(info.attributes['class'].isClass, true);
    expect(info.attributes['class'].bindings,
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
    expect(info.attributes['class'].bindings,
        equals(['x', 'y', 'z', 'w']));
    expect(info.node.attributes['class'].length, 30);
    expect(info.node.attributes['class'].contains('class1'), true);
    expect(info.node.attributes['class'].contains('class2'), true);
    expect(info.node.attributes['class'].contains('class3'), true);
    expect(info.node.attributes['class'].contains('class4'), true);
  });

  test('attribute - data style', () {
    var input = '<div data-style="x"></div>';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes.length, equals(1));
    expect(info.attributes['data-style'], isNotNull);
    expect(info.attributes['data-style'].isStyle, true);
    expect(info.attributes['data-style'].bindings, equals(['x']));
  });


  test('attribute - ui-event hookup', () {
    var input = '<input data-action="change:foo">';
    var info = analyzeElement(parseSubtree(input));
    expect(info.attributes, isEmpty);
    expect(info.events.keys, equals(['change']));
    var changeEvents = info.events['change'];
    expect(changeEvents.length, equals(1));
    expect(changeEvents[0].eventName, 'change');
    expect(changeEvents[0].action('bar', 'args'), 'foo(args)');
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

  test('template instantiate if (empty)', () {
    var elem = parseSubtree(
        '<template instantiate="if foo" is="x-if"></template>');
    var info = analyzeElement(elem);
    expect(info.hasIfCondition, false);
  });

  test('template instantiate if', () {
    var elem = parseSubtree('<template instantiate="if foo" is="x-if"><div>');
    var div = elem.query('div');
    TemplateInfo info = analyzeElement(elem);
    expect(info.hasIfCondition, true);
    expect(info.createdInCode, false);
    expect(info.children[0].node, equals(div));
    expect(info.children[0].createdInCode, true);
    expect(div.id, '');
    expect(elem.attributes, equals({
        'instantiate': 'if foo', 'is': 'x-if', 'id': '__e-0'}));
    expect(info.ifCondition, equals('foo'));
    expect(info.hasIterate, isFalse);
  });

  test('template iterate (invalid)', () {
    var elem = parseSubtree('<template iterate="bar" is="x-list"></template>');
    var info = analyzeElement(elem);

    expect(elem.attributes, equals({'iterate': 'bar', 'is': 'x-list'}));
    expect(info, isNot(new isInstanceOf<TemplateInfo>('TemplateInfo')),
      reason: 'example is not a valid template');
  });

  test('template iterate', () {
    var elem = parseSubtree('<template iterate="foo in bar" is="x-list"><div>');
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

  test('data-value', () {
    var elem = parseSubtree('<li is="x-todo-row" data-value="todo:x"></li>');
    var info = analyzeElement(elem);
    elem = elem.query('li');
    expect(info.attributes, isEmpty);
    expect(info.events, isEmpty);
    expect(info.values, equals({'todo': 'x'}));
  });

  group('analyzeDefinitions', () {
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
      expect(compInfo.constructor, equals('Foo'));
      expect(compInfo.element, equals(foo));
      expect(compInfo.hasConflict, isFalse);

      compInfo = info.declaredComponents[1];
      expect(compInfo.tagName, equals('x-bar'));
      expect(compInfo.constructor, equals('Bar42'));
      expect(compInfo.element, equals(bar));
      expect(compInfo.hasConflict, isFalse);
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
      expect(info.declaredComponents[0].constructor, equals('Baz'));
      expect(info.declaredComponents[1].constructor, equals('MyQuux'));
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
      var info = analyzeDefinitions(srcFile);
      expect(info.declaredComponents.length, equals(2));

      // no conflicts yet.
      expect(info.declaredComponents[0].hasConflict, isFalse);
      expect(info.declaredComponents[1].hasConflict, isFalse);

      var quuxElement = doc.query('element');
      expect(quuxElement, isNotNull);
      analyzeFile(srcFile, toPathMap({'main.html': info }));

      expect(info.components.length, equals(1));
      var compInfo = info.components['x-quux'];
      expect(compInfo.hasConflict, true);
      expect(compInfo.tagName, equals('x-quux'));
      expect(compInfo.constructor, equals('Quux'));
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
      expect(compInfo.constructor, equals('Quux'));
      expect(compInfo.element, equals(quux));
      expect(compInfo.hasConflict, isFalse);

      compInfo = info.declaredComponents[1];
      expect(compInfo.tagName, equals('x-quux2'));
      expect(compInfo.constructor, equals('Quux'));
      expect(compInfo.element, equals(quux2));
      expect(compInfo.hasConflict, isFalse);
    });
  });

  group('analyzeFile', () {
    test('binds components in same file', () {
      var doc = parse('<body><x-foo><element name="x-foo" constructor="Foo">');
      var srcFile = new SourceFile(new Path('main.html'))..document = doc;
      var info = analyzeDefinitions(srcFile);
      expect(info.declaredComponents.length, equals(1));

      analyzeFile(srcFile, toPathMap({ 'main.html': info }));
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
      expect(info.query('x-foo').component, equals(compInfo));
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
      expect(compInfo.hasConflict, true);
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
      expect(info.query('x-foo').component, equals(compInfo));
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
      var info = analyzeDefinitions(srcFile);
      analyzeFile(srcFile, toPathMap({ 'main.html': info }));
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
  });
}
