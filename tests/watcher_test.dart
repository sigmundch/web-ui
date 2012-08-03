// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Tests for the watcher library. */
#library('watcher_test');

#import('package:unittest/unittest.dart');

main() {
  test('simple watcher ', () {
    int x = 0;
    int valueSeen = null;
    var stop = watch(() => x, expectAsync1((_) { valueSeen = x; }));
    x = 22;
    dispatch();
    expect(valueSeen, equals(22));
    stop(); // cleanup
  });

  test('changes seen only on dispatch', () {
    int x = 0;
    int valueSeen = null;
    var stop = watch(() => x, expectAsync1((_) { valueSeen = x; }));
    x = 22; // not seen
    expect(valueSeen, isNull);
    x = 23;
    dispatch();
    expect(valueSeen, equals(23));
    stop(); // cleanup
  });

  test('changes not seen after unregistering', () {
    int x = 0;
    bool valuesSeen = false;
    var stop = watch(() => x, expectAsync1((_) { valuesSeen = true; }));
    x = 22;
    dispatch();
    stop();

    // nothing dispatched afterwards
    valuesSeen = false;
    x = 1;
    dispatch();
    expect(!valuesSeen);
  });

  test('unregister twice is ok', () {
    int x = 0;
    bool valuesSeen = false;
    var stop = watch(() => x, expectAsync1((_) { valuesSeen = true; }));
    x = 22;
    dispatch();
    stop();
    stop(); // unnecessary, but safe to call it again.
    valuesSeen = false;
    x = 1;
    dispatch();
    expect(!valuesSeen);
  });

  test('many changes seen', () {
    int x = 0;
    var valuesSeen = [];
    var stop = watch(() => x, expectAsync1((_) => valuesSeen.add(x), count: 3));
    x = 22;
    dispatch();
    x = 11;
    x = 12;
    dispatch();
    x = 14;
    dispatch();
    stop();
    expect(valuesSeen, orderedEquals([22, 12, 14]));
  });

  test('watch changes to shallow fields', () {
    B b = new B(3);
    int value = null;
    var stop = watch(() => b.c,
      expectAsync1((_) { value = b.c; }, count: 2));
    b.c = 5;
    dispatch();
    expect(value, equals(5));
    b.c = 6;
    dispatch();
    expect(value, equals(6));
    stop();
  });

  test('watch changes to deep fields', () {
    A a = new A();
    int value = null;
    var stop = watch(() => a.b.c,
      expectAsync1((_) { value = a.b.c; }, count: 2));
    a.b.c = 5;
    dispatch();
    expect(value, equals(5));
    a.b.c = 6;
    dispatch();
    expect(value, equals(6));
    stop();
  });

  test('watch changes to deep fields, change within', () {
    A a = new A();
    B b1 = a.b;
    B b2 = new B(2);
    int value = 3;
    var stop = watch(() => a.b.c,
      expectAsync1((_) { value = a.b.c; }, count: 2));
    expect(value, equals(3));
    dispatch();
    a.b = b2;
    dispatch();
    expect(value, equals(2));
    b2.c = 6;
    dispatch();
    expect(value, equals(6));
    b1.c = 16;
    dispatch();
    expect(value, equals(6)); // no change
    stop();
  });

  test('watch changes to lists', () {
    var list = [1, 2, 3];
    var copy = [1, 2, 3];
    var stop = watch(list, expectAsync1((_) {
      copy.clear();
      copy.addAll(list);
    }, count: 2));
    expect(copy, orderedEquals([1, 2, 3]));
    list[1] = 42;
    dispatch();
    expect(copy, orderedEquals([1, 42, 3]));
    list.removeLast();
    dispatch();
    expect(copy, orderedEquals([1, 42]));
    stop();
  });

  test('watch on lists is shallow only', () {
    var list = [new B(4)];
    // callback is not invoked (count: 0)
    var stop = watch(list, expectAsync1((_) {}, count: 0));
    dispatch();
    list[0].c = 42;
    dispatch();
    stop();
  });
}

class A {
  B b;
  A() : b = new B(3);
}

class B {
  int c;
  B(this.c);
}
