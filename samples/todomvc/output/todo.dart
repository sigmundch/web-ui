// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * TodoMVC sample application written with web-components and manually bound
 * models. This example illustrates what the executable code would look like for
 * an application written using Dart-adapted MDV-style templates. It can also be
 * used as a guideline for how our tools will generate code from the template
 * input.
 *
 * See the sibling 'input' directory to visualize what users would write to get
 * the code (manually) generated here.
 */
#library('output_todo');

#import('dart:html');

// Code from components
#import('footer.dart');
#import('newform.dart');
#import('item.dart');
#import('toggleall.dart');
// TODO(jmesserly): ideally these would be package: imports
#import('../../../list_component.dart');
#import('../../../if_component.dart');

#import('model.dart');
#import('../../../watcher.dart');
#import('../../../webcomponents.dart');

main() {
  _appSetUp();

  // listen on changes to #hash in the URL
  window.on.popState.add((_) {
    viewModel.showIncomplete = window.location.hash != '#/completed';
    viewModel.showDone = window.location.hash != '#/active';
    dispatch();
  });
}

/** Create the views and bind them to models (will be auto-generated). */
void _appSetUp() {
  initializeComponents();

  // create view.
  var body = new DocumentFragment.html(INITIAL_PAGE);
  manager.expandDeclarations(body);

  // attach model where needed.
  manager[body.query("[is=x-list]")].items = () => app.todos;

  // attach view to the document.
  document.body.nodes.add(body);
}

/** DOM describing the initial view of the app (will be auto-generated). */
final INITIAL_PAGE = """
  <section id="todoapp">
    <header id="header">
      <h1 class='title'>todos</h1>
      <div is="x-todo-form"></div>
    </header>
    <section id="main">
      <div is="x-toggle-all"></div>
      <ul id="todo-list">
        <template iterate="{{x in app.todos}}" is="x-list">
          <template instantiate="if x.isVisible" is="x-if">
            <li is="x-todo-row" data-todo="x"></li>
          </template>
        </template>
      </ul>
    </section>
    <template instantiate="if viewModel.hasElements" is="x-if">
      <footer is="x-todo-footer" id="footer"></footer>
    </template>
  </section>
  <footer id="info">
    <p>Double-click to edit a todo.</p>
    <p>Credits: the <a href="http://www.dartlang.org">Dart</a> team </p>
    <p>Part of <a href="http://todomvc.com">TodoMVC</a></p>
  </footer>
""";
