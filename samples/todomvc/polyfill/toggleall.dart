// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('toggleall');
#import('dart:html');
#import('../../../component.dart');
#import('../../../watcher.dart');
#import('model.dart');

/** The component associated with 'toggleall.html'. */
class ToggleComponent extends Component {

  bool get allChecked() => app.todos.length > 0 &&
      app.todos.every((t) => t.done);

  ToggleComponent(root, elem) : super('toggleall', root, elem);

  get _toggleAll() => root.query('#toggle-all');

  void markAll() => app.todos.forEach((t) { t.done = _toggleAll.checked; });
}
