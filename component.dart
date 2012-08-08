// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library has the base class for data-bound components.
 * It uses [watch] and [WebComponent] to implement [Component], and in
 * particular [Component.bind].
 */
#library('component');

#import('dart:mirrors');
#import('dart:html');
#import('watcher.dart');
#import('webcomponents.dart');
#import('lib/mdv_polyfill.dart', prefix: 'mdv');

typedef void Action();

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

  List<Action> _insertActions;
  List<Action> _removeActions;
  // TODO(jmesserly): you can also compute this from the DOM by walking the
  // parent chain.
  bool _inDocument = false;

  /**
   * Names in the declared scope of this component in a template, and their
   * corresponding values.
   */
  Map<String, Dynamic> scopedVariables;

  Component(this.name, this._root, this._element)
      : id = _id++,
        // TODO(jmesserly): initialize lazily
        _insertActions = [],
        _removeActions = [] {
    scopedVariables = {'this': this};
    _bindEvents(_root);
  }

  // TODO(jmesserly): rename these shadowRoot and host?
  Element get element() => _element;
  ShadowRoot get root() => _root;

  // TODO(sigmund): delete print statements or use logging library.
  void created() => print('$name $id-created');

  void inserted() {
    for (var action in _insertActions) action();
    print('$name $id-inserted');
    _inDocument = true;
  }

  void removed() {
    for (var action in _removeActions) action();
    print('$name $id-removed');
    _inDocument = false;
  }

  void attributeChanged(String name, String oldValue, String newValue) {
    print("$id-change on ${this.name}.$name $oldValue $newValue");
  }

  // TODO(jmesserly): evaluate these APIs to ensure they make sense
  /**
   * Registers a pair of actions to be run whenever this component is inserted
   * or removed from the document. If the node has already been inserted,
   * [onInserted] is executed immediately.
   */
  void lifecycleAction(Action onInserted, Action onRemoved) {
    _insertActions.add(onInserted);
    _removeActions.add(onRemoved);
    if (_inDocument) onInserted();
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

  void _bindEvents(Element node) {
    // TODO(jmesserly): this requires a full tree walk
    for (var child in node.elements) _bindEvents(child);

    // TODO(jmesserly): not sure if these should be data- attributes or
    // something else. Maybe we should use normal JS event bindings.
    var mirror = currentMirrorSystem();
    for (var key in node.dataAttributes.getKeys()) {
      if (key.startsWith('on-')) {
        var method = node.dataAttributes[key].trim();
        key = key.substring(3);
        if (!method.endsWith('()')) {
          throw new UnsupportedOperationException(
              'event handler $method for $key must be method call');
        } else {
          method = method.substring(0, method.length - 2);
        }
        var event = node.on[key];
        if (event == null) {
          throw new UnsupportedOperationException(
              'event $key not found on $node');
        }

        var self = mirror.mirrorOf(this);
        var caller = (e) {
          print('$name $id on-$key fired');
          // TODO(jmesserly): shouldn't we pass in event args somehow?
          // var args = [mirror.mirrorOf(e)];
          var future = self.invoke(method, []);
          dispatch();
          return future.value.reflectee;
        };

        lifecycleAction(() => event.add(caller), () => event.remove(caller));
      }
    }
  }
}
