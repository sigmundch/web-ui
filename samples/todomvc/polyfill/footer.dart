#library('footer');
#import('dart:html');
#import("package:webcomponents/component.dart");
#import("package:webcomponents/watcher.dart");
#import("package:webcomponents/webcomponents.dart");
#import("package:webcomponents/component.dart", prefix: "polyfill");
#import('model.dart');

class FooterComponent extends polyfill.Component {

  FooterComponent(element) : super('FooterComponent', element);

  int get doneCount() {
    int res = 0;
    app.todos.forEach((t) { if (t.done) res++; });
    return res;
  }

  int get remaining() => app.todos.length - doneCount;

  String get allClass() {
    if (window.location.hash == '' || window.location.hash == '#/') {
      return 'selected';
    } else {
      return null;
    }
  }

  String get activeClass() =>
      window.location.hash == '#/active' ?  'selected' : null;

  String get completedClass() =>
      window.location.hash == '#/completed' ?  'selected' : null;

  void clearDone() {
    app.todos = app.todos.filter((t) => !t.done);
  }

  bool get anyDone() => doneCount > 0;
}