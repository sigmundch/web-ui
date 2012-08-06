// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('component');
#import('dart:html');
#import('../../../watcher.dart');
#import('../../../webcomponents.dart');

/**
 * Base component that has some common functionality used by our components.
 * Eventually the code for [bind] should be baked into every custom element
 * (maybe in dart:html's Element class?).
 */
class Component extends WebComponent {
  int id;
  String name;
  static int _id = 0;
  Element _element;
  ShadowRoot _root;
  Map<String, Dynamic> scopedVariables;

  Component(this.name, this._root, this._element)
    : id = _id++ {
    scopedVariables = {'this': this};
  }

  Element get element() => _element;
  ShadowRoot get root() => _root;
  void created() => print('$name $id-created');
  void inserted() => print('$name $id-inserted');
  void removed() => print('$name $id-removed');

  void attributeChanged(String name, String oldValue, String newValue) {
    print("$id-change on ${this.name}.$name $oldValue $newValue");
  }

  Function bind(exp, callback, [debugName]) {
    var res = watch(exp, callback, debugName);
    if (exp is Function) {
      callback(new WatchEvent(null, exp()));
    } else {
      callback(new WatchEvent(null, exp));
    }
    return res;
  }
}
