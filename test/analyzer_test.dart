// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_test;

import 'package:html5lib/dom.dart';
import 'package:html5lib/html5parser.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:web_components/src/template/analyzer.dart';
import 'package:web_components/src/template/info.dart';
import 'package:web_components/src/template/source_file.dart';
import 'testing.dart';

main() {
  useVmConfiguration();
  useMockWorld();

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
    var input = '<input data-bind="value:x">';
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
    var input = '<input data-bind="value:x">';
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
    var input = '<input data-bind="checked:x">';
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
    var input = '<input data-action="change:foo()">';
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

  test('data-value', () {
    var elem = parseSubtree('<li is="x-todo-row" data-value="todo:x"></li>');
    var info = analyzeNode(elem).elements;
    expect(info[elem].attributes, isEmpty);
    expect(info[elem].events, isEmpty);
    expect(info[elem].values, equals({'todo': 'x'}));
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
      expect(info.componentLinks, equals(['foo.html', 'quux.html']));
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

    test('invalid elements', () {
      var doc = parse(
        '<body>'
          // without constructor
          '<element name="x-baz"></element>'
          // without tag name
          '<element constructor="Baz"></element>'
        '</body>'
      );
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
      var srcFile = new SourceFile('main.html')..document = doc;
      var info = analyzeDefinitions(srcFile);
      expect(info.declaredComponents.length, equals(2));

      // no conflicts yet.
      expect(info.declaredComponents[0].hasConflict, isFalse);
      expect(info.declaredComponents[1].hasConflict, isFalse);

      analyzeFile(srcFile, { 'main.html': info });

      expect(info.components.length, equals(1));
      var compInfo = info.components['x-quux'];
      expect(compInfo.hasConflict);
      expect(compInfo.tagName, equals('x-quux'));
      expect(compInfo.constructor, equals('Quux'));
      expect(compInfo.element, equals(doc.query('element')));
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
      var srcFile = new SourceFile('main.html')..document = doc;
      var info = analyzeDefinitions(srcFile);
      expect(info.declaredComponents.length, equals(1));

      analyzeFile(srcFile, { 'main.html': info });
      expect(info.components.getKeys(), equals(['x-foo']));

      var elemInfo = info.elements[doc.query('x-foo')];
      expect(elemInfo.component, equals(info.declaredComponents[0]));
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
      expect(info.components.getKeys(), equals(['x-foo']));
      var elemInfo = info.elements[files[0].document.query('x-foo')];
      var compInfo = fileInfo['foo.html'].declaredComponents[0];
      expect(elemInfo.component, equals(compInfo));
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
      expect(info.components.getKeys(), equals(['x-foo']));
      var elemInfo = info.elements[files[0].document.query('x-foo')];
      var compInfo = fileInfo['foo.html'].declaredComponents[0];
      expect(compInfo.hasConflict);
      expect(elemInfo.component, isNull);
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
      expect(info.components.getKeys(), equals(['x-foo']));
      var elemInfo = info.elements[files[0].document.query('x-foo')];
      var compInfo = fileInfo['foo.html'].declaredComponents[0];
      expect(elemInfo.component, equals(compInfo));
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
      expect(info.components.getKeys(), equals([]));
      var elemInfo = info.elements[files[0].document.query('x-foo')];
      expect(fileInfo['foo.html'].declaredComponents.length, isZero);
      expect(elemInfo.component, isNull);
    });
  });
}

FileInfo analyzeDefinitionsInTree(Document doc) =>
    analyzeDefinitions(new SourceFile('')..document = doc);

/** Parses files in [fileContents], with [mainHtmlFile] being the main file. */
List<SourceFile> parseFiles(Map<String, String> fileContents,
    [String mainHtmlFile = 'index.html']) {

  var result = <SourceFile>[];
  fileContents.forEach((filename, contents) {
    var src = new SourceFile(filename, mainDocument: filename == mainHtmlFile);
    src.document = parse(contents);
    result.add(src);
  });

  return result;
}

/** Analyze all files. */
Map<String, FileInfo> analyzeFiles(List<SourceFile> files) {
  var result = new Map<String, FileInfo>();
  // analyze definitions
  for (var file in files) {
    result[file.filename] = analyzeDefinitions(file);
  }

  // analyze file contents
  for (var file in files) {
    analyzeFile(file, result);
  }

  return result;
}
