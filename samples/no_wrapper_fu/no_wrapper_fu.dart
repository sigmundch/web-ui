// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('game_of_life');

#import('dart:html');
#import('dart:isolate');
#import('dart:math', prefix: 'Math');

#import('../../../../../dart-web-components/webcomponents.dart');


#source('package:game-of-life/components/components.dart');
typedef void Ping();

int GAME_SIZE = 20;
int CELL_SIZE = 20;

/** Singletons */
CellCoordinator get COORDINATOR {
  if (CellCoordinator._ONLY == null) {
    CellCoordinator._ONLY = new CellCoordinator._internal();
  }
  return CellCoordinator._ONLY;
}

void main() {
  _componentsSetup();
  COORDINATOR.populate();
  COORDINATOR.run();
  print('not implemented yet');
}

void _componentsSetup() {
  Map<String, Function> map = {
    'x-cell' : () => new Cell.component(),
    'x-control-panel' : () => new ControlPanel.component()
  };
  initializeComponents((String name) => map[name]);
}

class CellCoordinator {
  CellEvents on;
  Timer timer;

  CellCoordinator._internal() 
    : on = new CellCoordinatorEvents();

  void run() {
    timer = new Timer.repeating(200, (t) => on.next.forEach((f) => f()));
  }

  void populate() {
    // set up position styles
    var styles = new StyleElement();
    document.body.nodes.add(styles);
    var positionStyles = '';
    _forEachCell((i, j) => 
        positionStyles = _addPositionId(positionStyles, i, j));
    styles.innerHTML = positionStyles;

    // add cells
    _forEachCell((i, j) {
      var cell = new Cell();
      cell.coordinator = this;
      cell.id = 'x${i}y${j}';
      document.body.nodes.add(cell);
    });

    // TODO(samhop) fix webcomponents.dart so we don't have to do this
    queryAll('.cell').forEach((cell) => cell.bound());
  }

  static _forEachCell(f) {
    for (var i = 0; i < GAME_SIZE; i++) {
      for (var j = 0; j < GAME_SIZE; j++) {
        f(i, j);
      }
    }
  }
  
  // Singleton -- there is only one CellCoordinator
  static CellCoordinator _ONLY;

  static String _addPositionId(curr, i, j) =>
      '''
      $curr
      #x${i}y${j} {
        left: ${CELL_SIZE * i}px;
        top: ${CELL_SIZE * j}px;
      }
      ''';
}

class CellCoordinatorEvents implements Events {
  List<Ping> _next_list;

  CellCoordinatorEvents() : _next_list = <Ping>[];

  List<Ping> get next {
    return _next_list;
  }
}
