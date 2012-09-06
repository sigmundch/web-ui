// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('analyzer');

#import('package:unittest/unittest.dart');
#import('package:unittest/vm_config.dart');
#import('package:webcomponents/lib/html5parser/htmltree.dart');
#import('package:webcomponents/lib/html5parser/parser.dart', prefix: 'parser');
#import('package:webcomponents/tools/template/analyzer.dart');

main() {
  useVmConfiguration();
  test('parse single element', () {
    var input = '<div></div>';
    var elem = parseSubtree(input);
    expect(elem.toString(), input);
  });

  test('id extracted - shallow element', () {
    var input = '<div id="foo"></div>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].elementId, equals('foo'));
  });

  test('id extracted - deep element', () {
    var input = '<div><div><div id="foo"></div></div></div>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].elementId, isNull);
    expect(info[elem.children[0]].elementId, isNull);
    expect(info[elem.children[0].children[0]].elementId, equals('foo'));
  });

  test('id as identifier - found in dom', () {
    var input = '<div id="foo-bar"></div>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].idAsIdentifier, equals('_fooBar'));
  });

  test('id as identifier - many id names', () {
    identifierOf(String id) {
      var input = '<div id="$id"></div>';
      var elem = parseSubtree(input);
      return analyze(elem)[elem].idAsIdentifier;
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
    var info = analyze(elem);
    expect(info[elem].elementId, isNull);
    expect(info[elem.children[0]].elementId, isNull);
    expect(info[elem.children[0].children[0]].idAsIdentifier, equals('_fooBa'));
  });

  test('id as identifier - no id', () {
    var input = '<div></div>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].elementId, isNull);
    expect(info[elem].idAsIdentifier, isNull);
  });

  test('hasDataBinding - attribute w/o data', () {
    var input = '<input value="x"/>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(!info[elem].hasDataBinding);
  });

  test('hasDataBinding - attribute with data, 1 way binding', () {
    var input = '<input value="{{x}}"/>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].hasDataBinding);
  });

  test('hasDataBinding - attribute with data, 2 way binding', () {
    var input = '<input data-bind="{{value:x}}"/>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].hasDataBinding);
  });

  test('hasDataBinding - content with data', () {
    var input = '<div>{{x}}</div>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].hasDataBinding);
    expect(info[elem].contentBinding, equals('x'));
    expect(info[elem].contentExpression, equals(@"'${x}'"));
  });

  test('hasDataBinding - content with text and data', () {
    var input = '<div> a b {{x}}c</div>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].hasDataBinding);
    expect(info[elem].contentBinding, equals('x'));
    expect(info[elem].contentExpression, equals(@"' a b ${x}c'"));
  });

  test('attribute - no info', () {
    var input = '<input value="x"/>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].attributes, isNotNull);
    expect(info[elem].attributes, isEmpty);
  });

  test('attribute - 1 way binding input value', () {
    var input = '<input value="{{x}}"/>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['value'], isNotNull);
    expect(!info[elem].attributes['value'].isClass);
    expect(info[elem].attributes['value'].boundValue, equals('x'));
    expect(info[elem].events, isEmpty);
  });

  test('attribute - 2 way binding input value', () {
    var input = '<input data-bind="{{value:x}}"/>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['value'], isNotNull);
    expect(!info[elem].attributes['value'].isClass);
    expect(info[elem].attributes['value'].boundValue, equals('x'));
    expect(info[elem].events.length, equals(1));
    expect(info[elem].events['keyUp'].action('foo'), equals('x = foo.value'));
  });

  test('attribute - 1 way binding checkbox', () {
    var input = '<input checked="{{x}}"/>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['checked'], isNotNull);
    expect(!info[elem].attributes['checked'].isClass);
    expect(info[elem].attributes['checked'].boundValue, equals('x'));
    expect(info[elem].events, isEmpty);
  });

  test('attribute - 2 way binding checkbox', () {
    var input = '<input data-bind="{{checked:x}}"/>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
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
    var info = analyze(elem);
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['foo'], isNotNull);
    expect(!info[elem].attributes['foo'].isClass);
    expect(info[elem].attributes['foo'].boundValue, equals('x'));
  });

  test('attribute - single class', () {
    var input = '<div class="{{x}}"></div>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['class'], isNotNull);
    expect(info[elem].attributes['class'].isClass);
    expect(info[elem].attributes['class'].bindings, equals(['x']));
  });

  test('attribute - many classes', () {
    var input = '<div class="{{x}} {{y}}{{z}}  {{w}}"></div>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].attributes.length, equals(1));
    expect(info[elem].attributes['class'], isNotNull);
    expect(info[elem].attributes['class'].isClass);
    expect(info[elem].attributes['class'].bindings,
        equals(['x', 'y', 'z', 'w']));
  });

  test('attribute - ui-event hookup', () {
    var input = '<input data-on-change="{{foo()}}"/>';
    var elem = parseSubtree(input);
    var info = analyze(elem);
    expect(info[elem].attributes, isEmpty);
    expect(info[elem].events['change'], isNotNull);
    expect(info[elem].events['change'].eventName, 'change');
    expect(info[elem].events['change'].action(), 'foo()');
  });
}

HTMLElement parseSubtree(String elementHtml) {
  var root = parser.parseString('<html><body>$elementHtml</body></html>');
  var html = root.children[0].children[0];
  var body = html.children[0];
  return body.children[0];
}
