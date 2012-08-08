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
    // TODO(jmesserly): need to support things that are dynamically added
    // And ensure we're properly scoped.
    _bindData(_root);
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

  void _bindData(Element node) {
    // TODO(jmesserly): this full tree walk is problematic
    for (var child in node.elements) _bindData(child);

    _bindEvents(node);
    _bindAttributes(node);
    // TODO(jmesserly): _bindText(node);
  }

  void _bindEvents(Element node) {
    // TODO(jmesserly): not sure if these should be data- attributes or
    // something else. Maybe we should use normal JS event bindings.
    var mirror = currentMirrorSystem();
    node.dataAttributes.forEach((key, method) {
      if (!key.startsWith('on-')) return;

      key = key.substring(3);
      method = method.trim();
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
    });
  }

  void _bindAttributes(Element node) {
    if (node.tagName == 'TEMPLATE') {
      // Skip <template> nodes for now, they have more sophisticated attribute
      // grammar.
      return;
    }

    void bindAttr(key, value) {
      // TODO(jmesserly): we should support nesting {{ }} in strings
      if (!value.startsWith('{{') || !value.endsWith('}}')) return;

      value = value.substring(2, value.length - 2);
      var names = value.split('.');

      WatcherDisposer disposer = null;
      lifecycleAction(() {
        // TODO(jmesserly): what about two way binding? Mutation observers?
        // ??? initial state is wrong for checkbox
        disposer = bind(() => _mirrorGet(names), (e) {
          node.attributes[key] = e.newValue;
        });
      }, () => disposer());
    }

    node.attributes.forEach(bindAttr);
    node.dataAttributes.forEach(bindAttr);
  }

  _mirrorGet(List<String> names) {
    var mirror = currentMirrorSystem();
    var self = mirror.mirrorOf(this);
    for (var name in names) {
      self = self.invoke('get:$name', []).value;
    }
    return self.reflectee;
  }
}
