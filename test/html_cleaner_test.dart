// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library html_cleaner_test;

import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:web_components/src/html_cleaner.dart';
import 'package:web_components/src/info.dart';
import 'package:web_components/src/files.dart';
import 'package:web_components/src/file_system/path.dart';
import 'testing.dart';

main() {
  useVmConfiguration();
  useMockMessages();

  test('remove attributes with data bindings (1)', () {
    // Note: we use an id in all these tests so that the analyzer will not
    // inject one for us.
    var elem = parseSubtree('<div foo="{{bar}}" id="a"></div>');
    var info = analyzeElement(elem);
    expect(elem.outerHTML, '<div foo="{{bar}}" id="a"></div>');
    cleanHtmlNodes(info);
    expect(elem.outerHTML, '<div id="a"></div>');
  });

  test('remove attributes with data bindings (2)', () {
    var elem = parseSubtree('<div foo="{{bar}} baz" id="a"></div>');
    var info = analyzeElement(elem);
    expect(elem.outerHTML, '<div foo="{{bar}} baz" id="a"></div>');
    cleanHtmlNodes(info);
    expect(elem.outerHTML, '<div id="a"></div>');
  });

  test('preserve attributes with no data bindings', () {
    var elem = parseSubtree('<div foo="baz" id="a"></div>');
    var info = analyzeElement(elem);
    expect(elem.outerHTML, '<div foo="baz" id="a"></div>');
    cleanHtmlNodes(info);
    expect(elem.outerHTML, '<div foo="baz" id="a"></div>');
  });

  test("don't remove node for content with data bindings", () {
    var elem = parseSubtree('<div id="a">hi {{x}} friend</div>');
    var info = analyzeElement(elem);
    expect(elem.outerHTML, '<div id="a">hi  friend</div>');
    expect(elem.nodes.length, 3);
    expect(elem.nodes[0].value, 'hi ');
    expect(elem.nodes[1].value, '');
    expect(elem.nodes[2].value, ' friend');
    cleanHtmlNodes(info);
    expect(elem.outerHTML, '<div id="a">hi  friend</div>');
    expect(elem.nodes.length, 3);
    expect(elem.nodes[0].value, 'hi ');
    expect(elem.nodes[1].value, '');
    expect(elem.nodes[2].value, ' friend');
  });

  test('hide template nodes and remove their children', () {
    var input = '<div><template id="a" iterate="x in y">'
      '<div></div></template></div>';
    var elem = parseSubtree(input);
    var info = analyzeElement(elem);
    expect(elem.outerHTML, input);
    cleanHtmlNodes(info);
    expect(elem.outerHTML,
        '<div><template id="a" style="display:none"></template></div>');
  });

  test('remove children of iterate nodes', () {
    var input = '<div template="" id="a" iterate="x in y"><div></div></div>';
    var elem = parseSubtree(input);
    var info = analyzeElement(elem);
    expect(elem.outerHTML, input);
    cleanHtmlNodes(info);
    expect(elem.outerHTML, '<div id="a"></div>');
  });

  test('remove element declarations', () {
    var input = '<html><head></head><body>'
      '<element name="x-foo" constructor="Foo"></element>'
      '<element name="x-bar" constructor="Bar42"></element>'
      '</body></html>';
    var doc = parse(input);
    var file = new SourceFile(new Path('main.html'))..document = doc;
    var info = analyzeFiles([file])['main.html'];
    expect(doc.outerHTML, input);
    cleanHtmlNodes(info);
    expect(doc.outerHTML, '<html><head></head><body></body></html>');
  });
}
