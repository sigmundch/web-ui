// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('newform');
#import('dart:html');
#import('../../../component.dart');
#import('../../../watcher.dart');
#import('model.dart');

/** The component associated with 'newform.html'. */
class FormComponent extends Component {
  FormComponent(root, elem) : super('x-todo-form', root, elem);

  get _newTodo() => root.query("#new-todo");

  void addTodo() {
    app.todos.add(new Todo(_newTodo.value));
    _newTodo.value = '';
  }
}
