#library('item');
#import('dart:html');
#import("package:web_components/mirror_polyfill/component.dart");
#import("package:web_components/watcher.dart");
#import("package:web_components/mirror_polyfill/component.dart", prefix: "polyfill");

#import('model.dart');

class TodoItemComponent extends polyfill.Component {
  Todo todo;
  bool _editing = false;

  TodoItemComponent(element) : super('TodoItemComponent', element);

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
