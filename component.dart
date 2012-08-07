// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library has the base class for data-bound components.
 * It uses [watch] and [WebComponent] to implement [Component], and in
 * particular [Component.bind].
 */
#library('component');

#import('dart:html');
#import('watcher.dart');
#import('webcomponents.dart');

/**
 * Base component that has some common functionality used by our components.
 * Eventually the code for [bind] should be baked into every custom element
 * (maybe in dart:html's Element class?).
 */
class Component extends WebComponent {
  /**
   * Counter associated with this component, currently only used for debugging
   * purposes.
   */
  int id;

  /** Name for the kind of component, currently only used for debugging. */
  String name;

  static int _id = 0;
  Element _element;
  ShadowRoot _root;

  /**
   * Names in the declared scope of this component in a template, and their
   * corresponding values.
   */
  Map<String, Dynamic> scopedVariables;

  Component(this.name, this._root, this._element)
    : id = _id++ {
    scopedVariables = {'this': this};
  }

  Element get element() => _element;
  ShadowRoot get root() => _root;

  // TODO(sigmund): delete print statements or use logging library.
  void created() => print('$name $id-created');
  void inserted() => print('$name $id-inserted');
  void removed() => print('$name $id-removed');

  void attributeChanged(String name, String oldValue, String newValue) {
    print("$id-change on ${this.name}.$name $oldValue $newValue");
  }

  /** Adds a watcher for [exp], and executes [callback] immediately. */
  WatcherDisposer bind(exp, callback, [debugName]) {
    var res = watch(exp, callback, debugName);
    // TODO(jmesserly): this should be "is Getter" once dart2js bug is fixed.
    if (exp is Function) {
      callback(new WatchEvent(null, exp()));
    } else {
      callback(new WatchEvent(null, exp));
    }
    return res;
  }
}
