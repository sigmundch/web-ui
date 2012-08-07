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
#import('list_component.dart');
#import('if_component.dart');
#import('newform.dart');
#import('item.dart');
#import('toggleall.dart');

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
  _componentsSetUp();

  // create view.
  var body = new DocumentFragment.html(INITIAL_PAGE);
  manager.expandDeclarations(body);

  // attach model where needed.
  manager[body.query("[is=x-list]")].items = () => app.todos;

  // attach view to the document.
  document.body.nodes.add(body);
}

/** Set up components used by this application (will be auto-generated). */
void _componentsSetUp() {
  // use mirrors when they become available.
  Map<String, Function> map = {
    'x-todo-footer': (root, elem) => new FooterComponent(root, elem),
    'x-todo-form': (root, elem) => new FormComponent(root, elem),
    'x-toggle-all': (root, elem) => new ToggleComponent(root, elem),
    'x-list': (root, elem) => new ListComponent(root, elem),
    'x-if': (root, elem) {
      var res = new IfComponent(root, elem);
      var condition = elem.attributes['instantiate'].substring('if '.length);
      if (condition == 'viewModel.hasElements') {
        res.shouldShow = (_) => viewModel.hasElements;
      } else if (condition == 'viewModel.isVisible(x)') {
        res.shouldShow = (vars) => viewModel.isVisible(vars['x']);
      }
      return res;
    },
    'x-todo-row': (root, elem) => new TodoItemComponent(root, elem),
  };
  initializeComponents((String name) => map[name]);
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
          <template instantiate="if viewModel.isVisible(x)" is="x-if">
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
