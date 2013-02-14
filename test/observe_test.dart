// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Tests for some of the utility helper functions used by the compiler. */
library observe_test;

import 'dart:collection' show LinkedHashMap;
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'package:web_ui/observe.dart';
import 'package:web_ui/src/utils.dart' show setImmediate;

main() {
  useCompactVMConfiguration();

  group('TestObservable', () {
    test('no observers', () {
      var t = new TestObservable<int>(123);
      expect(t.value, 123);
      expect(t.rawValue, 123);
      t.value = 42;
      expect(t.value, 42);
      expect(t.rawValue, 42);
      expect(t.observers, null);
    });

    test('observe', () {
      var t = new TestObservable<int>(123);
      int called = 0;
      observe(() => t.value, expectAsync1((ChangeNotification n) {
        called++;
        expect(n.oldValue, 123);
        expect(n.newValue, 42);
      }));
      t.value = 41;
      t.value = 42;
      expect(called, 0, reason: 'changes delived async');
    });

    test('observe multiple changes', () {
      var t = new TestObservable<int>(123);
      observe(() => t.value, expectAsync1((ChangeNotification n) {
        if (n.oldValue == 123) {
          expect(n.newValue, 42);
          // Cause another change
          t.value = 777;
        } else {
          expect(n.oldValue, 42);
          expect(n.newValue, 777);
        }
      }, count: 2));
      t.value = 42;
    });

    test('multiple observers', () {
      var t = new TestObservable<int>(123);
      observe(() => t.value, expectAsync1((ChangeNotification n) {
        expect(n.oldValue, 123);
        expect(n.newValue, 42);
      }));
      observe(() => t.value + 1, expectAsync1((ChangeNotification n) {
        expect(n.oldValue, 124);
        expect(n.newValue, 43);
      }));
      t.value = 41;
      t.value = 42;
    });

    test('deliverChangesSync', () {
      var t = new TestObservable<int>(123);
      var notifications = [];
      observe(() => t.value, notifications.add);
      t.value = 41;
      t.value = 42;
      expect(notifications, [], reason: 'changes delived async');

      deliverChangesSync();
      expect(notifications, [_change(123, 42)]);
      t.value = 777;
      expect(notifications.length, 1, reason: 'changes delived async');

      deliverChangesSync();
      expect(notifications, [_change(123, 42), _change(42, 777)]);

      // Has no effect if there are no changes
      deliverChangesSync();
      expect(notifications, [_change(123, 42), _change(42, 777)]);
    });

    test('unobserve', () {
      var t = new TestObservable<int>(123);
      ChangeUnobserver unobserve;
      unobserve = observe(() => t.value, expectAsync1((n) {
        expect(n.oldValue, 123);
        expect(n.newValue, 42);
        unobserve();
        t.value = 777;
      }));
      t.value = 42;
    });

    test('observers fired in order', () {
      var t = new TestObservable<int>(123);
      int expectOldValue = 123;
      int expectNewValue = 42;
      observe(() => t.value, expectAsync1((n) {
        expect(n.oldValue, expectOldValue);
        expect(n.newValue, expectNewValue);

        // The second observer will see this change already, and only be called
        // once. However we'll be called a second time.
        t.value = 777;
        expectNewValue = 777;
        expectOldValue = 42;
      }, count: 2));

      observe(() => t.value + 1000, expectAsync1((n) {
        expect(n.oldValue, 1123);
        expect(n.newValue, 1777);
      }));

      // Make the initial change
      t.value = 42;
    });

    test('unobserve one of two observers', () {
      var t = new TestObservable<int>(123);
      ChangeUnobserver unobserve;
      unobserve = observe(() => t.value, expectAsync1((n) {
        expect(n.oldValue, 123);
        expect(n.newValue, 42);

        // This will not affect the other observer, so it still gets the event.
        unobserve();
        setImmediate(() => t.value = 777);
      }));
      int count = 0;
      observe(() => t.value + 1000, expectAsync1((n) {
        if (++count == 1) {
          expect(n.oldValue, 1123);
          expect(n.newValue, 1042);
        } else {
          expect(n.oldValue, 1042);
          expect(n.newValue, 1777);
        }
      }, count: 2));

      // Make the initial change
      t.value = 42;
    });

    test('notifyRead in getter', () {
      var t = new TestObservable<int>(123);

      observe(() {
        expect(observeReads, true);
        expect(t.observers, null);
        return t.value;
      }, (n) {});

      expect(observeReads, false);
      expect(t.observers, isNotNull);
    });

    test('notifyWrite in setter', () {
      var t = new TestObservable<int>(123);
      observe(() => t.value, (n) {});

      t.value = 42;
      expect(observeReads, false);
      expect(t.observers, null);

      // This will re-observe the expression.
      deliverChangesSync();

      expect(observeReads, false);
      expect(t.observers, isNotNull);
    });

    test('observe conditional async', () {
      var t = new TestObservable<bool>(false);
      var a = new TestObservable<int>(123);
      var b = new TestObservable<String>('hi');

      int count = 0;
      var oldValue = 'hi';
      observe(() => t.value ? a.value : b.value, expectAsync1((n) {
        expect(n.oldValue, oldValue);
        oldValue = t.value ? a.value : b.value;
        expect(n.newValue, oldValue);

        switch (++count) {
          case 1:
            // We are observing "a", change it
            a.value = 42;
            break;
          case 2:
            // Switch to observing "b"
            t.value = false;
            break;
          case 3:
            // Change "a", this should have no effect and will not fire a 4th
            // change event.
            a.value = 777;
            expect(a.observers, null);
            expect(b.observers, isNotNull);
            break;
          default:
            // Should not be able to reach this because of the "count" argument
            // to expectAsync1
            throw new StateError('unreachable');
        }
      }, count: 3));

      expect(t.observers, isNotNull);
      expect(a.observers, null);
      expect(b.observers, isNotNull);

      // Start off by changing "t" to true.
      t.value = true;
    });

    test('change limit set to null (unbounded)', () {
      const BIG_LIMIT = 1000;
      expect(circularNotifyLimit, lessThan(BIG_LIMIT));

      int oldLimit = circularNotifyLimit;
      circularNotifyLimit = null;
      try {
        var x = new TestObservable(false);
        var y = new TestObservable(false);

        int xCount = 0, yCount = 0;
        int limit = BIG_LIMIT;
        observe(() => x.value, (n) {
          if (++xCount < limit) y.value = x.value;
        });
        observe(() => y.value, (n) {
          if (++yCount < limit) x.value = !y.value;
        });

        // Kick off the cascading changes
        x.value = true;

        deliverChangesSync();

        expect(xCount, limit);
        expect(yCount, limit - 1);
      } finally {
        circularNotifyLimit = oldLimit;
      }
    });
  });

  group('ObservableReference', () {
    test('observe conditional sync', () {
      var t = new ObservableReference<bool>(false);
      var a = new ObservableReference<int>(123);
      var b = new ObservableReference<String>('hi');

      var notifications = [];
      observe(() => t.value ? a.value : b.value, notifications.add);

      // Start off by changing "t" to true, so we evaluate "a".
      t.value = true;
      deliverChangesSync();

      // This changes "a" which we should be observing.
      a.value = 42;
      deliverChangesSync();

      // This has no effect because we aren't using "b" yet.
      b.value = 'universe';
      deliverChangesSync();

      // Switch to use "b".
      t.value = false;
      deliverChangesSync();

      // This has no effect because we aren't using "a" anymore.
      a.value = 777;
      deliverChangesSync();

      expect(notifications, [
          _change('hi', 123),
          _change(123, 42),
          _change(42, 'universe')]);
    });
  });


  group('ObservableList', () {
    // TODO(jmesserly): need all standard List tests.

    test('observe length', () {
      var list = new ObservableList();
      var notification = null;
      observe(() => list.length, (n) { notification = n; });

      list.addAll([1, 2, 3]);
      expect(list, [1, 2, 3]);
      deliverChangesSync();
      expect(notification, _change(0, 3), reason: 'addAll changes length');

      list.add(4);
      expect(list, [1, 2, 3, 4]);
      deliverChangesSync();
      expect(notification, _change(3, 4), reason: 'add changes length');

      list.removeRange(1, 2);
      expect(list, [1, 4]);
      deliverChangesSync();
      expect(notification, _change(4, 2), reason: 'removeRange changes length');

      list.length = 5;
      expect(list, [1, 4, null, null, null]);
      deliverChangesSync();
      expect(notification, _change(2, 5), reason: 'length= changes length');
      notification = null;

      list[2] = 9000;
      expect(list, [1, 4, 9000, null, null]);
      deliverChangesSync();
      expect(notification, null, reason: '[]= does not change length');

      list.clear();
      expect(list, []);
      deliverChangesSync();
      expect(notification, _change(5, 0), reason: 'clear changes length');
    });

    test('observe index', () {
      var list = new ObservableList.from([1, 2, 3]);
      var notification = null;
      observe(() => list[1], (n) { notification = n; });

      list.add(4);
      expect(list, [1, 2, 3, 4]);
      deliverChangesSync();
      expect(notification, null,
          reason: 'add does not change existing items');

      list[1] = 777;
      expect(list, [1, 777, 3, 4]);
      deliverChangesSync();
      expect(notification, _change(2, 777));

      notification = null;
      list[2] = 9000;
      expect(list, [1, 777, 9000, 4]);
      deliverChangesSync();
      expect(notification, null,
          reason: 'setting a different index should not fire change');

      list[1] = 44;
      list[1] = 43;
      list[1] = 42;
      expect(list, [1, 42, 9000, 4]);
      deliverChangesSync();
      expect(notification, _change(777, 42));

      notification = null;
      list.length = 2;
      expect(list, [1, 42]);
      deliverChangesSync();
      expect(notification, null,
          reason: 'did not truncate the observed item');

      list.length = 1; // truncate
      list.add(2);
      expect(list, [1, 2]);
      deliverChangesSync();
      expect(notification, _change(42, 2),
          reason: 'item truncated and added back');

      notification = null;
      list.length = 1; // truncate
      list.add(2);
      expect(list, [1, 2]);
      deliverChangesSync();
      expect(notification, null,
          reason: 'truncated but added same item back');
    });

    test('toString', () {
      var list = new ObservableList.from([1, 2, 3]);
      var notification = null;
      observe(() => list.toString(), (n) { notification = n; });
      list[2] = 4;
      deliverChangesSync();
      expect(notification, _change('[1, 2, 3]', '[1, 2, 4]'));
    });
  });


  group('ObservableSet', () {
    // TODO(jmesserly): need all standard Set tests.

    test('observe length', () {
      var set = new ObservableSet();
      var notification = null;
      observe(() => set.length, (n) { notification = n; });

      set.addAll([1, 2, 3]);
      expect(set, [1, 2, 3]);
      deliverChangesSync();
      expect(notification, _change(0, 3), reason: 'addAll changes length');

      set.add(4);
      expect(set, [1, 2, 3, 4]);
      deliverChangesSync();
      expect(notification, _change(3, 4), reason: 'add changes length');

      set.removeAll([2, 3]);
      expect(set, [1, 4]);
      deliverChangesSync();
      expect(notification, _change(4, 2), reason: 'removeAll changes length');

      set.remove(1);
      expect(set, [4]);
      deliverChangesSync();
      expect(notification, _change(2, 1), reason: 'remove changes length');

      notification = null;
      set.add(4);
      expect(set, [4]);
      deliverChangesSync();
      expect(notification, null, reason: 'item already exists');

      set.clear();
      expect(set, []);
      deliverChangesSync();
      expect(notification, _change(1, 0), reason: 'clear changes length');
    });

    test('observe item', () {
      var set = new ObservableSet.from([1, 2, 3]);
      var notification = null;
      observe(() => set.contains(2), (n) { notification = n; });

      set.add(4);
      expect(set, [1, 2, 3, 4]);
      deliverChangesSync();
      expect(notification, null, reason: 'add does not change existing items');

      set.remove(3);
      expect(set, [1, 2, 4]);
      expect(notification, null,
          reason: 'removing an item does not change other items');

      set.remove(2);
      expect(set, [1, 4]);
      deliverChangesSync();
      expect(notification, _change(true, false));

      notification = null;
      set.removeAll([2, 3]);
      expect(set, [1, 4]);
      deliverChangesSync();
      expect(notification, null, reason: 'item already removed');

      set.add(2);
      expect(set, [1, 2, 4]);
      deliverChangesSync();
      expect(notification, _change(false, true), reason: 'item added again');
    });

    test('toString', () {
      var original = new Set.from([1, 2, 3]);
      var set = new ObservableSet.from(original);
      var notification = null;
      observe(() => set.toString(), (n) { notification = n; });
      set.add(4);
      deliverChangesSync();
      var updated = new Set.from([1, 2, 3, 4]);

      // Note: using Set.toString as the exectation, so the order is the same
      // as with ObservableSet, regardless of how hashCode is implemented.
      expect(notification, _change('$original', '$updated'));
    });
  });


  group('ObservableMap', () {
    // TODO(jmesserly): need all standard Map tests.

    test('observe length', () {
      var map = new ObservableMap();
      var notification = null;
      observe(() => map.length, (n) { notification = n; });

      map['a'] = 1;
      map.putIfAbsent('b', () => 2);
      map['c'] = 3;
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      deliverChangesSync();
      expect(notification, _change(0, 3), reason: 'adding changes length');

      map['d'] = 4;
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      deliverChangesSync();
      expect(notification, _change(3, 4), reason: 'add changes length');

      map.remove('b');
      map.remove('c');
      expect(map, {'a': 1, 'd': 4});
      deliverChangesSync();
      expect(notification, _change(4, 2), reason: 'removeRange changes length');

      notification = null;
      map['d'] = 9000;
      expect(map, {'a': 1, 'd': 9000});
      deliverChangesSync();
      expect(notification, null, reason: 'update item does not change length');

      map.clear();
      expect(map, {});
      deliverChangesSync();
      expect(notification, _change(2, 0), reason: 'clear changes length');
    });

    test('observe index', () {
      var map = new ObservableMap.from({'a': 1, 'b': 2, 'c': 3});
      var notification = null;
      observe(() => map['b'], (n) { notification = n; });

      map.putIfAbsent('d', () => 4);
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      deliverChangesSync();
      expect(notification, null, reason: 'add does not change existing items');

      map['b'] = null;
      expect(map, {'a': 1, 'b': null, 'c': 3, 'd': 4});
      deliverChangesSync();
      expect(notification, _change(2, null));

      map['b'] = 777;
      expect(map, {'a': 1, 'b': 777, 'c': 3, 'd': 4});
      deliverChangesSync();
      expect(notification, _change(null, 777));

      notification = null;
      map.putIfAbsent('b', () => 1234);
      expect(map, {'a': 1, 'b': 777, 'c': 3, 'd': 4});
      deliverChangesSync();
      expect(notification, null, reason: 'item already there');

      map['c'] = 9000;
      expect(map, {'a': 1, 'b': 777, 'c': 9000, 'd': 4});
      deliverChangesSync();
      expect(notification, null, reason: 'setting a different item');

      map['b'] = 44;
      map['b'] = 43;
      map['b'] = 42;
      expect(map, {'a': 1, 'b': 42, 'c': 9000, 'd': 4});
      deliverChangesSync();
      expect(notification, _change(777, 42));

      notification = null;
      map.remove('a');
      map.remove('d');
      expect(map, {'b': 42, 'c': 9000});
      deliverChangesSync();
      expect(notification, null, reason: 'did not remove the observed item');

      map.remove('b');
      map['b'] = 2;
      expect(map, {'b': 2, 'c': 9000});
      deliverChangesSync();
      expect(notification, _change(42, 2), reason: 'removed and added back');
    });

    test('toString', () {
      var map = new ObservableMap.from({'a': 1, 'b': 2},
          createMap: () => new LinkedHashMap());

      var notification = null;
      observe(() => map.toString(), (n) { notification = n; });
      map.remove('b');
      map['c'] = 3;
      deliverChangesSync();

      expect(notification, _change('{a: 1, b: 2}', '{a: 1, c: 3}'));
    });
  });

}

_change(oldValue, newValue) => new ChangeNotification(oldValue, newValue);

/**
 * This is similar to ObservableReference, but with fields public for testing.
 */
class TestObservable<T> {
  var observers;
  T rawValue;

  TestObservable([T initialValue]) : rawValue = initialValue;

  T get value {
    if (observeReads) observers = notifyRead(observers);
    return rawValue;
  }

  void set value(T newValue) {
    if (observers != null) observers = notifyWrite(observers);
    rawValue = newValue;
  }
}
