// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/** Common functions used by TodoMVC tests. */
library todomvc_common;

import 'dart:html';
import 'package:web_ui/watcher.dart';

void markChecked(item) {
  var node = document.queryAll('input[type=checkbox]')[item + 1];
  node.on.click.dispatch(new MouseEvent('click', window, 1, 0, 0, 0, 0, 0));
}

void checkAll() {
  var node = document.queryAll('input[type=checkbox]')[0];
  node.on.click.dispatch(new MouseEvent('click', window, 1, 0, 0, 0, 0, 0));
}

void clearCompleted() {
  var node = document.query('#clear-completed');
  node.on.click.dispatch(new MouseEvent('click', window, 1, 0, 0, 0, 0, 0));
}

var _newTodo = (() => document.query('#new-todo'))();
var _form = (() => document.query('#__e-0'))();

void addNote(String note) {
  _newTodo.value = note;
  _form.on.submit.dispatch(new Event('submit'));
  dispatch();
}
