// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('todoitem');
#import('dart:html');
#import('../../../component.dart');
#import('../../../watcher.dart');
#import('model.dart');

/** The component associated with 'item.html'. */
class TodoItemComponent extends Component {
  Todo todo;
  bool _editing = false;

  TodoItemComponent(root, elem) : super('x-todo-item', root, elem);

  String get itemClass() =>
      _editing ? 'editing' : (todo.done ? 'completed' : '');

  void edit() {
    _editing = true;
  }

  void update() {
    // TODO(jmesserly): do the two way binding automatically
    todo.task = root.query('input.edit').value;
    _editing = false;
  }

  void delete() {
    var list = app.todos;
    var index = list.indexOf(todo);
    if (index != -1) {
      list.removeRange(index, 1);
    }
  }

  void markDone() {
    // TODO(jmesserly): do the two way binding automatically
    todo.done = root.query('#checkbox').checked;
  }
}
