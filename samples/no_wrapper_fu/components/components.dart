// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef WebComponent ComponentConstructorThunk();

class Cell extends DivElementImpl implements WebComponent {
  Set<Cell> neighbors;
  ShadowRoot _root;
  CellCoordinator coordinator;

  bool get alive => this.classes.contains('alive');

  void step() {
    print('component ${this.id} steps');
  }

  static ComponentConstructorThunk _$constr;
  factory Cell.component() {
    if(_$constr == null) {
      _$constr = () => new Cell._internal();
    }
    var t1 = new DivElement();
    rewirePrototypeChain(t1, _$constr, 'Cell');
    return t1;
  }

  factory Cell() {
    return manager.expandHtml('<div is="x-cell"></div>');
  }

  Cell._internal();

  void created(ShadowRoot root) {
    _root = root;
    neighbors = new HashSet<Cell>();
    this.classes.add('cell');
  }

  void inserted() { }

  void bound() {
    this.on.click.add((event) => this.classes.toggle('alive'));
    coordinator.on.next.add(step);

    // find neighbors
    var parsedCoordinates = this.id.substring(1).split('y');
    var x = Math.parseInt(parsedCoordinates[0]);
    var y = Math.parseInt(parsedCoordinates[1]);
  }

  void attributeChanged(String name, String oldValue, String newValue) { }

  void removed() { }

}

class ControlPanel extends DivElementImpl implements WebComponent {
  ShadowRoot _root;
  CellCoordinator coordinator;

  static ComponentConstructorThunk _$constr;
  factory ControlPanel.component() {
    if(_$constr == null) {
      _$constr = () => new ControlPanel._internal();
    }
    var t1 = new DivElement();
    rewirePrototypeChain(t1, _$constr, 'ControlPanel');
    return t1;
  }

  factory ControlPanel() {
    return manager.expandHtml('<div is="x-control-panel"></div>');
  }

  ControlPanel._internal();

  void created(ShadowRoot root) {
    _root = root;
  }

  void inserted() { }

  void attributeChanged(String name, String oldValue, String newValue) { }

  void removed() { }
}
