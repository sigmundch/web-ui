// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('analyzer');

#import('package:html5lib/dom.dart');
#import('package:html5lib/html5parser.dart');
#import('package:unittest/unittest.dart');
#import('package:unittest/vm_config.dart');
#import('package:web_components/src/template/analyzer.dart');
#import('package:web_components/src/template/world.dart');

// TODO(jmesserly): we need tests for warnings from the analyzer.
class MockWorld extends World {
  MockWorld() : super(null);
  warning(message, [span, span1, span2]) {}
  error(message, [span, span1, span2]) {}
}

main() {
  useVmConfiguration();

  // TODO(jmesserly): fix the warning system to not need this.
  world = new MockWorld();

  test('parse single element', () {
    var input = '<div></div>';
    var elem = parseSubtree(input);
    expect(elem.outerHTML, input);
  });

  test('id extracted - shallow element', () {
    var input = '<div id="foo"></div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].elementId, equals('foo'));
  });

  test('id extracted - deep element', () {
    var input = '<div><div><div id="foo"></div></div></div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].elementId, isNull);
    expect(info[elem.nodes[0]].elementId, isNull);
    expect(info[elem.nodes[0].nodes[0]].elementId, equals('foo'));
  });

  test('ElementInfo.toString()', () {
    var input = '<div id="foo"></div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].toString().startsWith('#<ElementInfo '));
  });

  test('id as identifier - found in dom', () {
    var input = '<div id="foo-bar"></div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].idAsIdentifier, equals('_fooBar'));
  });

  test('id as identifier - many id names', () {
    identifierOf(String id) {
      var input = '<div id="$id"></div>';
      var elem = parseSubtree(input);
      return analyzeNode(elem).elements[elem].idAsIdentifier;
    }
    expect(identifierOf('foo-bar'), equals('_fooBar'));
    expect(identifierOf('foo-b'), equals('_fooB'));
    expect(identifierOf('foo-'), equals('_foo'));
    expect(identifierOf('foo--bar'), equals('_fooBar'));
    expect(identifierOf('foo--bar---z'), equals('_fooBarZ'));
  });

  test('id as identifier - deep element', () {
    var input = '<div><div><div id="foo-ba"></div></div></div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].elementId, isNull);
    expect(info[elem.nodes[0]].elementId, isNull);
    expect(info[elem.nodes[0].nodes[0]].idAsIdentifier, equals('_fooBa'));
  });

  test('id as identifier - no id', () {
    var input = '<div></div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].elementId, isNull);
    expect(info[elem].idAsIdentifier, isNull);
  });

  test('hasDataBinding - attribute w/o data', () {
    var input = '<input value="x">';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(!info[elem].hasDataBinding);
  });

  test('hasDataBinding - attribute with data, 1 way binding', () {
    var input = '<input value="{{x}}">';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].hasDataBinding);
  });

  test('hasDataBinding - attribute with data, 2 way binding', () {
    var input = '<input data-bind="{{value:x}}">';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].hasDataBinding);
  });

  test('hasDataBinding - content with data', () {
    var input = '<div>{{x}}</div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].hasDataBinding);
    expect(info[elem].contentBinding, equals('x'));
    expect(info[elem].contentExpression, equals(@"'${x}'"));
  });

  test('hasDataBinding - content with text and data', () {
    var input = '<div> a b {{x}}c</div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].hasDataBinding);
    expect(info[elem].contentBinding, equals('x'));
    expect(info[elem].contentExpression, equals(@"' a b ${x}c'"));
  });

  test('attribute - no info', () {
    var input = '<input value="x">';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes, isNotNull);
    expect(info[elem].attributes, isEmpty);
  });

  test('attribute - 1 way binding input value', () {
    var input = '<input value="{{x}}">';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['value'], isNotNull);
    expect(!info[elem].attributes['value'].isClass);
    expect(info[elem].attributes['value'].boundValue, equals('x'));
    expect(info[elem].events, isEmpty);
  });

  test('attribute - 2 way binding input value', () {
    var input = '<input data-bind="{{value:x}}">';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['value'], isNotNull);
    expect(!info[elem].attributes['value'].isClass);
    expect(info[elem].attributes['value'].boundValue, equals('x'));
    expect(info[elem].events.length, equals(1));
    expect(info[elem].events['keyUp'].action('foo'), equals('x = foo.value'));
  });

  test('attribute - 1 way binding checkbox', () {
    var input = '<input checked="{{x}}">';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['checked'], isNotNull);
    expect(!info[elem].attributes['checked'].isClass);
    expect(info[elem].attributes['checked'].boundValue, equals('x'));
    expect(info[elem].events, isEmpty);
  });

  test('attribute - 2 way binding checkbox', () {
    var input = '<input data-bind="{{checked:x}}">';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['checked'], isNotNull);
    expect(!info[elem].attributes['checked'].isClass);
    expect(info[elem].attributes['checked'].boundValue, equals('x'));
    expect(info[elem].events.length, equals(1));
    expect(info[elem].events['click'].action('foo'), equals('x = foo.checked'));
  });

  test('attribute - 1 way binding, normal field', () {
    var input = '<div foo="{{x}}"></div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['foo'], isNotNull);
    expect(!info[elem].attributes['foo'].isClass);
    expect(info[elem].attributes['foo'].boundValue, equals('x'));
  });

  test('attribute - single class', () {
    var input = '<div class="{{x}}"></div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['class'], isNotNull);
    expect(info[elem].attributes['class'].isClass);
    expect(info[elem].attributes['class'].bindings, equals(['x']));
  });

  test('attribute - many classes', () {
    var input = '<div class="{{x}} {{y}}{{z}}  {{w}}"></div>';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['class'], isNotNull);
    expect(info[elem].attributes['class'].isClass);
    expect(info[elem].attributes['class'].bindings,
        equals(['x', 'y', 'z', 'w']));
  });

  test('attribute - ui-event hookup', () {
    var input = '<input data-on-change="{{foo()}}">';
    var elem = parseSubtree(input);
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes, isEmpty);
    expect(info[elem].events['change'], isNotNull);
    expect(info[elem].events['change'].eventName, 'change');
    expect(info[elem].events['change'].action(), 'foo()');
  });

  test('template element', () {
    var elem = parseSubtree('<template></template>');
    var info = analyzeNode(elem).elements[elem];
    expect(info is! TemplateInfo, reason: 'example does not need TemplateInfo');
  });

  // TODO(jmesserly): I'm not sure we are implementing correct behavior for
  // `<template instantiate>` in Model-Driven-Views.
  test('template instantiate (invalid)', () {
    var elem = parseSubtree('<template instantiate="foo"></template>');
    var info = analyzeNode(elem).elements[elem];
    expect(elem.attributes, equals({'instantiate': 'foo'}));
    expect(info is! TemplateInfo, reason: 'example is not a valid template');
  });

  test('template instantiate if', () {
    var elem = parseSubtree(
        '<template instantiate="if foo" is="x-if"></template>');
    TemplateInfo info = analyzeNode(elem).elements[elem];
    expect(info.hasIfCondition);
    expect(elem.attributes, equals({
      'instantiate': 'if foo', 'is': 'x-if', 'id' : '__e-0'}));
    expect(info.ifCondition, equals('foo'));
    expect(info.hasIterate, isFalse);
  });

  test('template iterate (invalid)', () {
    var elem = parseSubtree('<template iterate="bar" is="x-list"></template>');
    var info = analyzeNode(elem).elements[elem];
    expect(elem.attributes, equals({'iterate': 'bar', 'is': 'x-list'}));
    expect(info is! TemplateInfo, reason: 'example is not a valid template');
  });

  test('template iterate', () {
    var elem = parseSubtree('<template iterate="foo in bar" is="x-list">');
    TemplateInfo info = analyzeNode(elem).elements[elem];
    expect(elem.attributes, equals({
      'iterate': 'foo in bar', 'is': 'x-list', 'id' : '__e-0'}));
    expect(info.ifCondition, isNull);
    expect(info.loopVariable, equals('foo'));
    expect(info.loopItems, equals('bar'));
  });


  test('used components', () {
    var elem = parseSubtree('<foo is="x-fancy-button"><bar>');
    var info = analyzeNode(elem).usedComponents;
    expect(info, equals(['x-fancy-button']));
  });

  test('used components 2', () {
    var elem = parseSubtree('<div is="x-foo"><span is="x-bar">');
    var info = new List.from(analyzeNode(elem).usedComponents);
    info.sort((x, y) => x.compareTo(y));
    expect(info, equals(['x-bar', 'x-foo']));
  });

  test('data-value', () {
    var elem = parseSubtree('<li is="x-todo-row" data-value="todo:x"></li>');
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes, isEmpty);
    expect(info[elem].events, isEmpty);
    expect(info[elem].values, equals({'todo': 'x'}));
  });
}

Element parseSubtree(String html) => parseFragment(html).nodes[0];
