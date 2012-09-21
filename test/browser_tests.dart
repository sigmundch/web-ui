// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): need a lot more tests here
// TODO(jmesserly): using the _tests suffix to prevent run.sh from running this
// Ideally this would be called component_test.
/** Basic sanity test for [IfComponent] and [ListComponent]. */
library browser_tests;

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:web_components/mirror_polyfill/web_components.dart';
import 'package:web_components/mirror_polyfill/component.dart';
import 'package:web_components/watcher.dart';

class Item {
  bool visible = true;
}

class AppModel {
  final List<Item> items;
  bool showFooter = false;

  AppModel() : items = [];
}

AppModel app;

main() {
  useHtmlConfiguration();

  app = new AppModel();
  _appSetUp();

  test('if was created', () {
    var ifEl = query('#cool-if');
    expect(ifEl, isNotNull);
    var ifComp = manager[ifEl];
    expect(ifComp, isNotNull);
    app.showFooter = true;
    expect(ifComp.shouldShow());
    app.showFooter = false;
    expect(!ifComp.shouldShow());
  });

  test('if responds to state change', () {
    var ifEl = query('#cool-if');
    var ifComp = manager[ifEl];
    expect(!ifComp.shouldShow());
    app.showFooter = true;
    expect(query('#cool-footer'), isNull);
    dispatch();
    expect(ifComp.shouldShow());
    var footer = query('#cool-footer');

    expect(footer, isNotNull);
    expect(footer.parent, equals(ifEl.parent));

    var children = footer.parent.nodes;
    expect(children.indexOf(footer), greaterThan(children.indexOf(ifEl)));

    app.showFooter = false;
    expect(query('#cool-footer'), isNotNull);
    dispatch();
    expect(query('#cool-footer'), isNull);
  });


  test('list was created', () {
    var listEl = query('#cool-list');
    expect(listEl, isNotNull);
    var list = manager[listEl];
    expect(list, isNotNull);
    expect(list.items(), equals(app.items));
  });

  test('list responds to state change', () {
    app.items.add(new Item());
    app.items.add(new Item());
    app.items.add(new Item());

    var ul = query('#cool-list-host');
    expect(queryAll('.cool-item').length, 0);
    dispatch();
    // TODO(jmesserly): investigate why this only updates async
    window.setTimeout(expectAsync0(() {
      expect(queryAll('.cool-item').length, 3);
      var items = queryAll('.cool-item');
      expect(items[0].parent, equals(ul));

      app.items[1].visible = false;
      dispatch();
      expect(queryAll('.cool-item').length, 2);

      app.items.clear();
      dispatch();
      expect(queryAll('.cool-item').length, 0);
    }), 0);
  });
}

/** Create the views and bind them to models (will be auto-generated). */
void _appSetUp() {
  // create view.
  var body = new DocumentFragment.html(INITIAL_PAGE);
  // Use mirrors when they become available.
  // TODO(jacobr): handle x-if

  manager.expandDeclarations(body, app);

  // attach view to the document.
  document.body.nodes.add(body);
}

/** DOM describing the initial view of the app (will be auto-generated). */
final INITIAL_PAGE = """
  <ul id="cool-list-host">
    <template iterate="{{item in app.items}}" is="x-list" id="cool-list">
      <template instantiate="if item.visible" is="x-if">
        <li class="cool-item">some cool data</li>
      </template>
    </template>
  </ul>
  <template instantiate="if app.showFooter" is="x-if" id="cool-if">
    <footer id="cool-footer"></footer>
  </template>
""";
