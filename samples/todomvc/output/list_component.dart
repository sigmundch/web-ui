// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('list_component');

#import('dart:html');
#import('component.dart');
#import('../../../watcher.dart');
#import('../../../webcomponents.dart');

/**
 * A generic list component implementing 'template iterate'. This component is
 * provided with our library and tools.
 */
// TODO(sigmund): move to a shared location.
class ListComponent extends Component {
  Getter<List> items;
  final String _loopVar;

  ListComponent(root, elem)
    : super('list', root, elem),
      _loopVar = const RegExp(@"{{(.*) in .*}}").firstMatch(
          elem.attributes['iterate']).group(1);

  Element _childTemplate;
  Element _parent;
  Function _stop1;

  void created() {
    // TODO(sigmund): support document fragments, not just a single child.
    // TODO(sigmund): use logging and not assertions.
    assert(element.elements.length == 1);
    _childTemplate = element.elements[0];
    element.nodes.clear();
    _parent = element.parent;
  }

  void inserted() {
    root.nodes.clear();
    _stop1 = bind(items, (_) {
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
        component.scopedVariables = new Map.from(scopedVariables);
        component.scopedVariables[_loopVar] = x;
        _parent.nodes.add(child);
      }
    });
  }

  void removed() {
    _stop1();
    for (var n in _parent.elements) {
      var wrapper = manager[n];
      if (wrapper != null && wrapper != this) {
        wrapper.removed();
      }
    }
  }
}
