// Generated Dart class from HTML template.
// DO NOT EDIT.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('list_component');

#import('dart:html');
#import('component.dart');
#import('watcher.dart');
#import('webcomponents.dart');

/**
 * A web component implementing `<template iterate=...>`.
 */
class ListComponent extends Component {
  Getter<List> items;
  String _loopVar;
  Element _childTemplate;
  Element _parent;
  WatcherDisposer _stopWatcher;

  ListComponent() : super('list');

  void created(ShadowRoot shadowRoot) {
    // TODO(sigmund): support document fragments, not just a single child.
    // TODO(sigmund): use logging and not assertions.
    root = shadowRoot;
    _loopVar = const RegExp(@"{{(.*) in .*}}").firstMatch(
        element.attributes['iterate']).group(1);
    assert(element.elements.length == 1);
    _childTemplate = element.elements[0];
    element.nodes.clear();
    _parent = element.parent;
  }

  void inserted() {
    root.nodes.clear();
    _stopWatcher = bind(items, (_) {
      for (var n in _parent.elements) {
        var wrapper = manager[n];
        if (wrapper != this) {
          if (wrapper != null) wrapper.removed();
          n.remove();
        }
      }
      for (var x in items()) {
        var child = _childTemplate.clone(true);
        var component = manager.expandElement(child);
        // TODO(jmesserly): should support children that aren't WebComponents
        component.scopedVariables = new Map.from(scopedVariables);
        component.scopedVariables[_loopVar] = x;
        _parent.nodes.add(child);
      }
    });
  }

  void removed() {
    _stopWatcher();
    for (var n in _parent.elements) {
      var wrapper = manager[n];
      if (wrapper != null && wrapper != this) {
        wrapper.removed();
      }
    }
  }
}
