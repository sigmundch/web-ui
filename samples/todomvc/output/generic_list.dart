// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('generic_list');

#import('dart:html');
#import('component.dart');
#import('../../../watcher.dart');
#import('../../../webcomponents.dart');

/**
 * A generic list component implementing 'template iterate'. This component is
 * provided with our library and tools.
 */
// TODO(sigmund): move to a shared location.
class GenericListComponent extends Component {
  Getter<List> items;
  String loopVar;

  GenericListComponent(root, elem) : super('list', root, elem) {
    var loopExp = elem.attributes['iterate'];
    // TODO(sigmund): assert loopExp matches "{{something in something}}"
    loopVar = loopExp.split(' ')[0].substring(2);
  }

  Element _childTemplate;
  Element _parent;
  Function _stop1;

  void created() {
    // TODO(sigmund): support document fragments, not just a single child.
    _childTemplate = element.elements[0];
    element.nodes.clear();
    _parent = element.parent;
  }

  void inserted() {
    root.nodes.clear();
    _stop1 = bind(items, (_) => regenerateList());
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

  void regenerateList() {
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
      component.scopedVariables =
          new Map<String, Dynamic>.from(scopedVariables);
      component.scopedVariables[loopVar] = x;
      _parent.nodes.add(child);
    }
  }
}
