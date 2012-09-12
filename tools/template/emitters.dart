// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Collects several code emitters for the template tool. */
// TODO(sigmund): add visitor that applies all emitters on a component
// TODO(sigmund): add support for conditionals, so context is changed at that
// point.
#library('emitters');

#import('package:html5lib/treebuilders/simpletree.dart');
#import('code_printer.dart');
#import('analyzer.dart');

/**
 * An emitter for a web component feature.  It collects all the logic for
 * emitting a particular feature (such as data-binding, event hookup) with
 * respect to a single HTML element.
 */
abstract class Emitter {
  /** Element for which code is being emitted. */
  Element elem;

  /** Information about the element for which code is being emitted. */
  ElementInfo elemInfo;

  Emitter(this.elem, this.elemInfo);

  /** Emit declarations needed by this emitter's feature. */
  void emitDeclarations(Context context) {
  }

  /** Emit feature-related statemetns in the `created` method. */
  void emitCreated(Context context) {
  }

  /** Emit feature-related statemetns in the `inserted` method. */
  void emitInserted(Context context) {
  }

  /** Emit feature-related statemetns in the `removed` method. */
  void emitRemoved(Context context) {
  }

  // The following are helper methods to make it simpler to write emitters.

  /** Generates a unique Dart identifier in the given [context]. */
  String newName(Context context, String prefix) =>
      '${prefix}${context.nextId()}';

  /** Write output. */
  write(Context context, String s) => context.printer.add(s);
}

/**
 * Context used by an emitter. Typically representing where to generate code
 * and additional information, such as total number of generated identifiers.
 */
class Context {
  CodePrinter printer;
  Context([CodePrinter p]) : printer = p != null ? p : new CodePrinter();

  // TODO(sigmund): keep separate counters for ids, listeners, watchers?
  int _totalIds = 0;
  int nextId() => ++_totalIds;
}

/**
 * Generates a field for any element that has either event listeners or data
 * bindings.
 */
class ElementFieldEmitter extends Emitter {
  ElementFieldEmitter(Element elem, ElementInfo info)
      : super(elem, info);

  void emitDeclarations(Context context) {
    if (elemInfo.elemField != null) {
      write(context, 'var ${elemInfo.elemField};');
    }
  }

  void emitCreated(Context context) {
    if (elemInfo.elemField != null) {
      write(context,
          "${elemInfo.elemField} = root.query('#${elemInfo.elementId}');");
    }
  }

  void emitInserted(Context context) {}
  void emitRemoved(Context context) {}
}

/**
 * Generates event listeners attached to a node and code that attaches/detaches
 * the listener.
 */
class EventListenerEmitter extends Emitter {

  EventListenerEmitter(Element elem, ElementInfo info)
      : super(elem, info);

  /** Generate a field for each listener, so it can be detached on `removed`. */
  void emitDeclarations(Context context) {
    elemInfo.events.forEach((name, eventInfo) {
      eventInfo.listenerField = newName(context, '_listener_${name}_');
      write(context, 'EventListener ${eventInfo.listenerField};');
    });
  }

  /** Nothing to do. */
  void emitCreated(Context context) {}

  /** Define the listeners. */
  // TODO(sigmund): should the definition of listener be done in `created`?
  void emitInserted(Context context) {
    var elemField = elemInfo.elemField;
    elemInfo.events.forEach((name, eventInfo) {
      var field = eventInfo.listenerField;
      write(context, '''
          $field = (_) {
            ${eventInfo.action(elemField)};
            dispatch();
          };
          $elemField.on['${eventInfo.eventName}'].add($field);
      ''');
    });
  }

  /** Emit feature-related statemetns in the `removed` method. */
  void emitRemoved(Context context) {
    var elemField = elemInfo.elemField;
    elemInfo.events.forEach((name, eventInfo) {
      var field = eventInfo.listenerField;
      write(context, '''
          $elemField.on['${eventInfo.eventName}'].remove($field);
          $field = null;
      ''');
    });
  }
}

/** Generates watchers that listen on data changes and update a DOM element. */
class DataBindingEmitter extends Emitter {
  DataBindingEmitter(Element elem, ElementInfo info)
      : super(elem, info);

  /** Emit a field for each disposer function. */
  void emitDeclarations(Context context) {
    var elemField = elemInfo.elemField;
    elemInfo.attributes.forEach((name, attrInfo) {
      attrInfo.stopperNames = [];
      attrInfo.bindings.forEach((b) {
        var stopperName = newName(context, '_stopWatcher${elemField}_');
        attrInfo.stopperNames.add(stopperName);
        write(context, 'WatcherDisposer $stopperName;');
      });
    });

    if (elemInfo.contentBinding != null) {
      elemInfo.stopperName = newName(context, '_stopWatcher${elemField}_');
      write(context, 'WatcherDisposer ${elemInfo.stopperName};');
    }
  }

  /** Nothing to do. */
  void emitCreated(Context context) {
  }

  /** Watchers for each data binding. */
  void emitInserted(Context context) {
    var elemField = elemInfo.elemField;
    // stop-functions for watchers associated with data-bound attributes
    elemInfo.attributes.forEach((name, attrInfo) {
      if (attrInfo.isClass) {
        for (int i = 0; i < attrInfo.bindings.length; i++) {
          var stopperName = attrInfo.stopperNames[i];
          var exp = attrInfo.bindings[i];
          write(context, '''
              $stopperName = bind(() => $exp, (e) {
                if (e.oldValue != null && e.oldValue != '') {
                  $elemField.classes.remove(e.oldValue);
                }
                if (e.newValue != null && e.newValue != '') {
                  $elemField.classes.add(e.newValue);
                }
              });
          ''');
        }
      } else {
        var val = attrInfo.boundValue;
        var stopperName = attrInfo.stopperNames[0];
        write(context, '''
            $stopperName = bind(() => $val, (e) {
              $elemField.$name = e.newValue;
            });
        ''');
      }
    });

    // stop-functions for watchers associated with data-bound content
    if (elemInfo.contentBinding != null) {
      var stopperName = elemInfo.stopperName;
      // TODO(sigmund): track all subexpressions, not just the first one.
      var val = elemInfo.contentBinding;
      write(context, '''
          $stopperName = bind(() => $val, (e) {
            $elemField.innerHTML = ${elemInfo.contentExpression};
          });
      ''');
    }
  }

  /** Call the dispose method on all watchers. */
  void emitRemoved(Context context) {
    elemInfo.attributes.forEach((name, attrInfo) {
      attrInfo.stopperNames.forEach((stopperName) {
        write(context, '$stopperName();');
      });
    });
    if (elemInfo.contentBinding != null) {
      write(context, '${elemInfo.stopperName}();');
    }
  }
}
