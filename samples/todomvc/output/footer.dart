// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('footer');
#import('dart:html');
#import('../../../component.dart');
#import('../../../watcher.dart');
#import('../../../webcomponents.dart');
#import('model.dart');

/** The component associated with 'footer.html'. */
class FooterComponent extends Component {
  FooterComponent(root, elem) : super('footer', root, elem);

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
