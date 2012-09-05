function Isolate() {}
init();

var $$ = {};
var $ = Isolate.$isolateProperties;
$$.ExceptionImplementation = {"":
 ["_msg"],
 super: "Object",
 toString$0: function() {
  var t1 = this._msg;
  return t1 == null ? 'Exception' : 'Exception: ' + $.S(t1);
}
};

$$.HashMapImplementation = {"":
 ["_keys?", "_values", "_loadLimit", "_numberOfEntries", "_numberOfDeleted"],
 super: "Object",
 _probeForAdding$1: function(key) {
  var t1 = $.hashCode(key);
  if (t1 !== (t1 | 0))
    return this._probeForAdding$1$bailout(1, key, t1, 0, 0, 0);
  var t3 = $.get$length(this._keys);
  if (t3 !== (t3 | 0))
    return this._probeForAdding$1$bailout(2, key, t1, t3, 0, 0);
  var hash = (t1 & t3 - 1) >>> 0;
  for (var numberOfProbes = 1, insertionIndex = -1; true;) {
    t1 = this._keys;
    if (typeof t1 !== 'string' && (typeof t1 !== 'object' || t1 === null || t1.constructor !== Array && !t1.is$JavaScriptIndexingBehavior()))
      return this._probeForAdding$1$bailout(3, key, hash, numberOfProbes, insertionIndex, t1);
    if (hash < 0 || hash >= t1.length)
      throw $.ioore(hash);
    var existingKey = t1[hash];
    if (existingKey == null) {
      if (insertionIndex < 0)
        return hash;
      return insertionIndex;
    } else if ($.eqB(existingKey, key))
      return hash;
    else if (insertionIndex < 0 && $.CTC15 === existingKey)
      insertionIndex = hash;
    var numberOfProbes0 = numberOfProbes + 1;
    hash = $.HashMapImplementation__nextProbe(hash, numberOfProbes, $.get$length(this._keys));
    if (hash !== (hash | 0))
      return this._probeForAdding$1$bailout(4, numberOfProbes0, key, insertionIndex, hash, 0);
    numberOfProbes = numberOfProbes0;
  }
},
 _probeForAdding$1$bailout: function(state, env0, env1, env2, env3, env4) {
  switch (state) {
    case 1:
      var key = env0;
      t1 = env1;
      break;
    case 2:
      key = env0;
      t1 = env1;
      t3 = env2;
      break;
    case 3:
      key = env0;
      hash = env1;
      numberOfProbes = env2;
      insertionIndex = env3;
      t1 = env4;
      break;
    case 4:
      numberOfProbes0 = env0;
      key = env1;
      insertionIndex = env2;
      hash = env3;
      break;
  }
  switch (state) {
    case 0:
      var t1 = $.hashCode(key);
    case 1:
      state = 0;
      var t3 = $.get$length(this._keys);
    case 2:
      state = 0;
      var hash = $.and(t1, $.sub(t3, 1));
      var numberOfProbes = 1;
      var insertionIndex = -1;
    default:
      L0:
        while (true)
          switch (state) {
            case 0:
              if (!true)
                break L0;
              t1 = this._keys;
            case 3:
              state = 0;
              var existingKey = $.index(t1, hash);
              if (existingKey == null) {
                if ($.ltB(insertionIndex, 0))
                  return hash;
                return insertionIndex;
              } else if ($.eqB(existingKey, key))
                return hash;
              else if ($.ltB(insertionIndex, 0) && $.CTC15 === existingKey)
                insertionIndex = hash;
              var numberOfProbes0 = numberOfProbes + 1;
              hash = $.HashMapImplementation__nextProbe(hash, numberOfProbes, $.get$length(this._keys));
            case 4:
              state = 0;
              numberOfProbes = numberOfProbes0;
          }
  }
},
 _probeForLookup$1: function(key) {
  var hash = $.and($.hashCode(key), $.sub($.get$length(this._keys), 1));
  if (hash !== (hash | 0))
    return this._probeForLookup$1$bailout(1, key, hash);
  for (var numberOfProbes = 1; true;) {
    var existingKey = $.index(this._keys, hash);
    if (existingKey == null)
      return -1;
    if ($.eqB(existingKey, key))
      return hash;
    var numberOfProbes0 = numberOfProbes + 1;
    hash = $.HashMapImplementation__nextProbe(hash, numberOfProbes, $.get$length(this._keys));
    numberOfProbes = numberOfProbes0;
  }
},
 _probeForLookup$1$bailout: function(state, key, hash) {
  for (var numberOfProbes = 1; true;) {
    var existingKey = $.index(this._keys, hash);
    if (existingKey == null)
      return -1;
    if ($.eqB(existingKey, key))
      return hash;
    var numberOfProbes0 = numberOfProbes + 1;
    hash = $.HashMapImplementation__nextProbe(hash, numberOfProbes, $.get$length(this._keys));
    numberOfProbes = numberOfProbes0;
  }
},
 _ensureCapacity$0: function() {
  var newNumberOfEntries = $.add(this._numberOfEntries, 1);
  if ($.geB(newNumberOfEntries, this._loadLimit)) {
    this._grow$1($.mul($.get$length(this._keys), 2));
    return;
  }
  var numberOfFree = $.sub($.sub($.get$length(this._keys), newNumberOfEntries), this._numberOfDeleted);
  if ($.gtB(this._numberOfDeleted, numberOfFree))
    this._grow$1($.get$length(this._keys));
},
 _grow$1: function(newCapacity) {
  var capacity = $.get$length(this._keys);
  if (typeof capacity !== 'number')
    return this._grow$1$bailout(1, newCapacity, capacity, 0, 0);
  this._loadLimit = $.tdiv($.mul(newCapacity, 3), 4);
  var oldKeys = this._keys;
  if (typeof oldKeys !== 'string' && (typeof oldKeys !== 'object' || oldKeys === null || oldKeys.constructor !== Array && !oldKeys.is$JavaScriptIndexingBehavior()))
    return this._grow$1$bailout(2, newCapacity, oldKeys, capacity, 0);
  var oldValues = this._values;
  if (typeof oldValues !== 'string' && (typeof oldValues !== 'object' || oldValues === null || oldValues.constructor !== Array && !oldValues.is$JavaScriptIndexingBehavior()))
    return this._grow$1$bailout(3, newCapacity, oldKeys, oldValues, capacity);
  this._keys = $.ListImplementation_List(newCapacity);
  this._values = $.ListImplementation_List(newCapacity, $.getRuntimeTypeInfo(this).V);
  for (var i = 0; i < capacity; ++i) {
    if (i < 0 || i >= oldKeys.length)
      throw $.ioore(i);
    var key = oldKeys[i];
    if (key == null || key === $.CTC15)
      continue;
    if (i < 0 || i >= oldValues.length)
      throw $.ioore(i);
    var value = oldValues[i];
    var newIndex = this._probeForAdding$1(key);
    $.indexSet(this._keys, newIndex, key);
    $.indexSet(this._values, newIndex, value);
  }
  this._numberOfDeleted = 0;
},
 _grow$1$bailout: function(state, env0, env1, env2, env3) {
  switch (state) {
    case 1:
      var newCapacity = env0;
      capacity = env1;
      break;
    case 2:
      newCapacity = env0;
      oldKeys = env1;
      capacity = env2;
      break;
    case 3:
      newCapacity = env0;
      oldKeys = env1;
      oldValues = env2;
      capacity = env3;
      break;
  }
  switch (state) {
    case 0:
      var capacity = $.get$length(this._keys);
    case 1:
      state = 0;
      this._loadLimit = $.tdiv($.mul(newCapacity, 3), 4);
      var oldKeys = this._keys;
    case 2:
      state = 0;
      var oldValues = this._values;
    case 3:
      state = 0;
      this._keys = $.ListImplementation_List(newCapacity);
      this._values = $.ListImplementation_List(newCapacity, $.getRuntimeTypeInfo(this).V);
      for (var i = 0; $.ltB(i, capacity); ++i) {
        var key = $.index(oldKeys, i);
        if (key == null || key === $.CTC15)
          continue;
        var value = $.index(oldValues, i);
        var newIndex = this._probeForAdding$1(key);
        $.indexSet(this._keys, newIndex, key);
        $.indexSet(this._values, newIndex, value);
      }
      this._numberOfDeleted = 0;
  }
},
 clear$0: function() {
  this._numberOfEntries = 0;
  this._numberOfDeleted = 0;
  var length$ = $.get$length(this._keys);
  if (typeof length$ !== 'number')
    return this.clear$0$bailout(1, length$);
  for (var i = 0; i < length$; ++i) {
    $.indexSet(this._keys, i, null);
    $.indexSet(this._values, i, null);
  }
},
 clear$0$bailout: function(state, length$) {
  for (var i = 0; $.ltB(i, length$); ++i) {
    $.indexSet(this._keys, i, null);
    $.indexSet(this._values, i, null);
  }
},
 operator$indexSet$2: function(key, value) {
  this._ensureCapacity$0();
  var index = this._probeForAdding$1(key);
  if ($.index(this._keys, index) == null || $.index(this._keys, index) === $.CTC15)
    this._numberOfEntries = $.add(this._numberOfEntries, 1);
  $.indexSet(this._keys, index, key);
  $.indexSet(this._values, index, value);
},
 operator$index$1: function(key) {
  var index = this._probeForLookup$1(key);
  if ($.ltB(index, 0))
    return;
  return $.index(this._values, index);
},
 isEmpty$0: function() {
  return $.eq(this._numberOfEntries, 0);
},
 get$length: function() {
  return this._numberOfEntries;
},
 forEach$1: function(f) {
  var length$ = $.get$length(this._keys);
  if (typeof length$ !== 'number')
    return this.forEach$1$bailout(1, f, length$);
  for (var i = 0; i < length$; ++i) {
    var key = $.index(this._keys, i);
    if (!(key == null) && !(key === $.CTC15))
      f.call$2(key, $.index(this._values, i));
  }
},
 forEach$1$bailout: function(state, f, length$) {
  for (var i = 0; $.ltB(i, length$); ++i) {
    var key = $.index(this._keys, i);
    if (!(key == null) && !(key === $.CTC15))
      f.call$2(key, $.index(this._values, i));
  }
},
 getValues$0: function() {
  var t1 = {};
  var list = $.ListImplementation_List($.get$length(this), $.getRuntimeTypeInfo(this).V);
  t1.i_1 = 0;
  this.forEach$1(new $.HashMapImplementation_getValues__(list, t1));
  return list;
},
 containsKey$1: function(key) {
  return !$.eqB(this._probeForLookup$1(key), -1);
},
 toString$0: function() {
  return $.Maps_mapToString(this);
},
 HashMapImplementation$0: function() {
  this._numberOfEntries = 0;
  this._numberOfDeleted = 0;
  this._loadLimit = 6;
  this._keys = $.ListImplementation_List(8);
  this._values = $.ListImplementation_List(8, $.getRuntimeTypeInfo(this).V);
},
 is$Map: function() { return true; }
};

$$.HashSetImplementation = {"":
 ["_backingMap?"],
 super: "Object",
 clear$0: function() {
  $.clear(this._backingMap);
},
 add$1: function(value) {
  var t1 = this._backingMap;
  if (typeof t1 !== 'object' || t1 === null || (t1.constructor !== Array || !!t1.immutable$list) && !t1.is$JavaScriptIndexingBehavior())
    return this.add$1$bailout(1, t1, value);
  if (value !== (value | 0))
    throw $.iae(value);
  if (value < 0 || value >= t1.length)
    throw $.ioore(value);
  t1[value] = value;
},
 add$1$bailout: function(state, t1, value) {
  $.indexSet(t1, value, value);
},
 addAll$1: function(collection) {
  $.forEach(collection, new $.HashSetImplementation_addAll__(this));
},
 forEach$1: function(f) {
  $.forEach(this._backingMap, new $.HashSetImplementation_forEach__(f));
},
 filter$1: function(f) {
  var result = $.HashSetImplementation$($.getRuntimeTypeInfo(this).E);
  $.forEach(this._backingMap, new $.HashSetImplementation_filter__(result, f));
  return result;
},
 isEmpty$0: function() {
  return $.isEmpty(this._backingMap);
},
 get$length: function() {
  return $.get$length(this._backingMap);
},
 iterator$0: function() {
  return $.HashSetIterator$(this, $.getRuntimeTypeInfo(this).E);
},
 toString$0: function() {
  return $.Collections_collectionToString(this);
},
 HashSetImplementation$0: function() {
  this._backingMap = $.HashMapImplementation$($.getRuntimeTypeInfo(this).E, $.getRuntimeTypeInfo(this).E);
},
 is$Collection: function() { return true; }
};

$$.HashSetIterator = {"":
 ["_entries", "_nextValidIndex"],
 super: "Object",
 hasNext$0: function() {
  var t1 = this._nextValidIndex;
  var t2 = this._entries;
  if (typeof t2 !== 'string' && (typeof t2 !== 'object' || t2 === null || t2.constructor !== Array && !t2.is$JavaScriptIndexingBehavior()))
    return this.hasNext$0$bailout(1, t1, t2);
  var t4 = t2.length;
  if (t1 >= t4)
    return false;
  if (t1 !== (t1 | 0))
    throw $.iae(t1);
  if (t1 < 0 || t1 >= t4)
    throw $.ioore(t1);
  if (t2[t1] === $.CTC15)
    this._advance$0();
  return this._nextValidIndex < t2.length;
},
 hasNext$0$bailout: function(state, t1, t2) {
  if ($.geB(t1, $.get$length(t2)))
    return false;
  if ($.index(t2, this._nextValidIndex) === $.CTC15)
    this._advance$0();
  return $.lt(this._nextValidIndex, $.get$length(t2));
},
 next$0: function() {
  if (this.hasNext$0() !== true)
    throw $.captureStackTrace($.CTC12);
  var t1 = this._entries;
  if (typeof t1 !== 'string' && (typeof t1 !== 'object' || t1 === null || t1.constructor !== Array && !t1.is$JavaScriptIndexingBehavior()))
    return this.next$0$bailout(1, t1);
  var t3 = this._nextValidIndex;
  if (t3 !== (t3 | 0))
    throw $.iae(t3);
  if (t3 < 0 || t3 >= t1.length)
    throw $.ioore(t3);
  var res = t1[t3];
  this._advance$0();
  return res;
},
 next$0$bailout: function(state, t1) {
  var res = $.index(t1, this._nextValidIndex);
  this._advance$0();
  return res;
},
 _advance$0: function() {
  var t1 = this._entries;
  if (typeof t1 !== 'string' && (typeof t1 !== 'object' || t1 === null || t1.constructor !== Array && !t1.is$JavaScriptIndexingBehavior()))
    return this._advance$0$bailout(1, t1);
  var length$ = t1.length;
  var entry = null;
  do {
    var t2 = this._nextValidIndex + 1;
    this._nextValidIndex = t2;
    if (t2 >= length$)
      break;
    t2 = this._nextValidIndex;
    if (t2 !== (t2 | 0))
      throw $.iae(t2);
    if (t2 < 0 || t2 >= t1.length)
      throw $.ioore(t2);
    entry = t1[t2];
  } while (entry == null || entry === $.CTC15);
},
 _advance$0$bailout: function(state, t1) {
  var length$ = $.get$length(t1);
  var entry = null;
  do {
    var t2 = this._nextValidIndex + 1;
    this._nextValidIndex = t2;
    if ($.geB(t2, length$))
      break;
    entry = $.index(t1, this._nextValidIndex);
  } while (entry == null || entry === $.CTC15);
},
 HashSetIterator$1: function(set_) {
  this._advance$0();
}
};

$$._DeletedKeySentinel = {"":
 [],
 super: "Object"
};

$$.KeyValuePair = {"":
 ["key?", "value="],
 super: "Object"
};

$$.LinkedHashMapImplementation = {"":
 ["_list", "_map"],
 super: "Object",
 operator$indexSet$2: function(key, value) {
  var t1 = this._map;
  if (typeof t1 !== 'object' || t1 === null || (t1.constructor !== Array || !!t1.immutable$list) && !t1.is$JavaScriptIndexingBehavior())
    return this.operator$indexSet$2$bailout(1, key, value, t1);
  if (t1.containsKey$1(key) === true) {
    if (key !== (key | 0))
      throw $.iae(key);
    if (key < 0 || key >= t1.length)
      throw $.ioore(key);
    t1[key].get$element().set$value(value);
  } else {
    var t2 = this._list;
    $.addLast(t2, $.KeyValuePair$(key, value, $.getRuntimeTypeInfo(this).K, $.getRuntimeTypeInfo(this).V));
    t2 = t2.lastEntry$0();
    if (key !== (key | 0))
      throw $.iae(key);
    if (key < 0 || key >= t1.length)
      throw $.ioore(key);
    t1[key] = t2;
  }
},
 operator$indexSet$2$bailout: function(state, key, value, t1) {
  if (t1.containsKey$1(key) === true)
    $.index(t1, key).get$element().set$value(value);
  else {
    var t2 = this._list;
    $.addLast(t2, $.KeyValuePair$(key, value, $.getRuntimeTypeInfo(this).K, $.getRuntimeTypeInfo(this).V));
    $.indexSet(t1, key, t2.lastEntry$0());
  }
},
 operator$index$1: function(key) {
  var entry = $.index(this._map, key);
  if (entry == null)
    return;
  return entry.get$element().get$value();
},
 getValues$0: function() {
  var t1 = {};
  var list = $.ListImplementation_List($.get$length(this), $.getRuntimeTypeInfo(this).V);
  t1.index_1 = 0;
  $.forEach(this._list, new $.LinkedHashMapImplementation_getValues__(list, t1));
  return list;
},
 forEach$1: function(f) {
  $.forEach(this._list, new $.LinkedHashMapImplementation_forEach__(f));
},
 containsKey$1: function(key) {
  return this._map.containsKey$1(key);
},
 get$length: function() {
  return $.get$length(this._map);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 clear$0: function() {
  $.clear(this._map);
  $.clear(this._list);
},
 toString$0: function() {
  return $.Maps_mapToString(this);
},
 LinkedHashMapImplementation$0: function() {
  this._map = $.HashMapImplementation$($.getRuntimeTypeInfo(this).K, 'DoubleLinkedQueueEntry<KeyValuePair<K, V>>');
  this._list = $.DoubleLinkedQueue$('KeyValuePair<K, V>');
},
 is$Map: function() { return true; }
};

$$.DoubleLinkedQueueEntry = {"":
 ["_previous=", "_next=", "_element?"],
 super: "Object",
 _link$2: function(p, n) {
  this._next = n;
  this._previous = p;
  p.set$_next(this);
  n.set$_previous(this);
},
 prepend$1: function(e) {
  $.DoubleLinkedQueueEntry$(e, $.getRuntimeTypeInfo(this).E)._link$2(this._previous, this);
},
 remove$0: function() {
  var t1 = this._next;
  this._previous.set$_next(t1);
  t1 = this._previous;
  this._next.set$_previous(t1);
  this._next = null;
  this._previous = null;
  return this._element;
},
 _asNonSentinelEntry$0: function() {
  return this;
},
 previousEntry$0: function() {
  return this._previous._asNonSentinelEntry$0();
},
 get$element: function() {
  return this._element;
},
 set$element: function(e) {
  this._element = e;
},
 DoubleLinkedQueueEntry$1: function(e) {
  this._element = e;
}
};

$$._DoubleLinkedQueueEntrySentinel = {"":
 ["_previous", "_next", "_element"],
 super: "DoubleLinkedQueueEntry",
 remove$0: function() {
  throw $.captureStackTrace($.CTC14);
},
 _asNonSentinelEntry$0: function() {
  return;
},
 set$element: function(e) {
},
 get$element: function() {
  throw $.captureStackTrace($.CTC14);
},
 _DoubleLinkedQueueEntrySentinel$0: function() {
  this._link$2(this, this);
}
};

$$.DoubleLinkedQueue = {"":
 ["_sentinel"],
 super: "Object",
 addLast$1: function(value) {
  this._sentinel.prepend$1(value);
},
 add$1: function(value) {
  this.addLast$1(value);
},
 addAll$1: function(collection) {
  for (var t1 = $.iterator(collection); t1.hasNext$0() === true;)
    this.add$1(t1.next$0());
},
 removeLast$0: function() {
  return this._sentinel.get$_previous().remove$0();
},
 first$0: function() {
  return this._sentinel.get$_next().get$element();
},
 get$first: function() { return new $.BoundClosure(this, 'first$0'); },
 last$0: function() {
  return this._sentinel.get$_previous().get$element();
},
 lastEntry$0: function() {
  return this._sentinel.previousEntry$0();
},
 get$length: function() {
  var t1 = {};
  t1.counter_1 = 0;
  this.forEach$1(new $.DoubleLinkedQueue_length__(t1));
  return t1.counter_1;
},
 isEmpty$0: function() {
  var t1 = this._sentinel;
  var t2 = t1.get$_next();
  return t2 == null ? t1 == null : t2 === t1;
},
 clear$0: function() {
  var t1 = this._sentinel;
  t1.set$_next(t1);
  t1.set$_previous(t1);
},
 forEach$1: function(f) {
  var t1 = this._sentinel;
  var entry = t1.get$_next();
  for (; !(entry == null ? t1 == null : entry === t1);) {
    var nextEntry = entry.get$_next();
    f.call$1(entry.get$_element());
    entry = nextEntry;
  }
},
 filter$1: function(f) {
  var other = $.DoubleLinkedQueue$($.getRuntimeTypeInfo(this).E);
  var t1 = this._sentinel;
  var entry = t1.get$_next();
  for (; !(entry == null ? t1 == null : entry === t1);) {
    var nextEntry = entry.get$_next();
    if (f.call$1(entry.get$_element()) === true)
      other.addLast$1(entry.get$_element());
    entry = nextEntry;
  }
  return other;
},
 iterator$0: function() {
  return $._DoubleLinkedQueueIterator$(this._sentinel, $.getRuntimeTypeInfo(this).E);
},
 toString$0: function() {
  return $.Collections_collectionToString(this);
},
 DoubleLinkedQueue$0: function() {
  this._sentinel = $._DoubleLinkedQueueEntrySentinel$($.getRuntimeTypeInfo(this).E);
},
 is$Collection: function() { return true; }
};

$$._DoubleLinkedQueueIterator = {"":
 ["_sentinel", "_currentEntry"],
 super: "Object",
 hasNext$0: function() {
  var t1 = this._currentEntry.get$_next();
  var t2 = this._sentinel;
  return !(t1 == null ? t2 == null : t1 === t2);
},
 next$0: function() {
  if (this.hasNext$0() !== true)
    throw $.captureStackTrace($.CTC12);
  this._currentEntry = this._currentEntry.get$_next();
  return this._currentEntry.get$element();
},
 _DoubleLinkedQueueIterator$1: function(_sentinel) {
  this._currentEntry = this._sentinel;
}
};

$$.JSSyntaxRegExp = {"":
 ["_ignoreCase", "_multiLine", "_lib2_pattern"],
 super: "Object",
 firstMatch$1: function(str) {
  var m = $.regExpExec(this, $.checkString(str));
  if (m == null)
    return;
  var matchStart = $.regExpMatchStart(m);
  var t1 = $.get$length($.index(m, 0));
  if (typeof t1 !== 'number')
    throw $.iae(t1);
  var matchEnd = matchStart + t1;
  return $._MatchImplementation$(this.get$pattern(), str, matchStart, matchEnd, m);
},
 hasMatch$1: function(str) {
  return $.regExpTest(this, $.checkString(str));
},
 get$pattern: function() {
  return this._lib2_pattern;
},
 get$multiLine: function() {
  return this._multiLine;
},
 get$ignoreCase: function() {
  return this._ignoreCase;
},
 is$RegExp: true
};

$$.StringBufferImpl = {"":
 ["_buffer", "_length"],
 super: "Object",
 get$length: function() {
  return this._length;
},
 isEmpty$0: function() {
  return this._length === 0;
},
 add$1: function(obj) {
  var str = $.toString(obj);
  if (str == null || $.isEmpty(str) === true)
    return this;
  $.add$1(this._buffer, str);
  var t1 = this._length;
  if (typeof t1 !== 'number')
    return this.add$1$bailout(1, str, t1);
  var t3 = $.get$length(str);
  if (typeof t3 !== 'number')
    return this.add$1$bailout(2, t1, t3);
  this._length = t1 + t3;
  return this;
},
 add$1$bailout: function(state, env0, env1) {
  switch (state) {
    case 1:
      str = env0;
      t1 = env1;
      break;
    case 2:
      t1 = env0;
      t3 = env1;
      break;
  }
  switch (state) {
    case 0:
      var str = $.toString(obj);
      if (str == null || $.isEmpty(str) === true)
        return this;
      $.add$1(this._buffer, str);
      var t1 = this._length;
    case 1:
      state = 0;
      var t3 = $.get$length(str);
    case 2:
      state = 0;
      this._length = $.add(t1, t3);
      return this;
  }
},
 addAll$1: function(objects) {
  for (var t1 = $.iterator(objects); t1.hasNext$0() === true;)
    this.add$1(t1.next$0());
  return this;
},
 clear$0: function() {
  this._buffer = $.ListImplementation_List(null, 'String');
  this._length = 0;
  return this;
},
 toString$0: function() {
  if ($.get$length(this._buffer) === 0)
    return '';
  if ($.get$length(this._buffer) === 1)
    return $.index(this._buffer, 0);
  var result = $.stringJoinUnchecked($.StringImplementation__toJsStringArray(this._buffer), '');
  $.clear(this._buffer);
  $.add$1(this._buffer, result);
  return result;
},
 StringBufferImpl$1: function(content$) {
  this.clear$0();
  this.add$1(content$);
}
};

$$._MatchImplementation = {"":
 ["pattern", "str", "_start", "_end", "_groups"],
 super: "Object",
 group$1: function(index) {
  return $.index(this._groups, index);
},
 operator$index$1: function(index) {
  return this.group$1(index);
}
};

$$.IndexOutOfRangeException = {"":
 ["_lib0_value?"],
 super: "Object",
 toString$0: function() {
  return 'IndexOutOfRangeException: ' + $.S(this._lib0_value);
}
};

$$.IllegalAccessException = {"":
 [],
 super: "Object",
 toString$0: function() {
  return 'Attempt to modify an immutable object';
}
};

$$.NoSuchMethodException = {"":
 ["_receiver", "_functionName", "_arguments", "_existingArgumentNames"],
 super: "Object",
 toString$0: function() {
  var sb = $.StringBufferImpl$('');
  var t1 = this._arguments;
  if (typeof t1 !== 'string' && (typeof t1 !== 'object' || t1 === null || t1.constructor !== Array && !t1.is$JavaScriptIndexingBehavior()))
    return this.toString$0$bailout(1, t1, sb);
  var i = 0;
  for (; i < t1.length; ++i) {
    if (i > 0)
      sb.add$1(', ');
    if (i < 0 || i >= t1.length)
      throw $.ioore(i);
    sb.add$1(t1[i]);
  }
  t1 = this._existingArgumentNames;
  if (typeof t1 !== 'string' && (typeof t1 !== 'object' || t1 === null || t1.constructor !== Array && !t1.is$JavaScriptIndexingBehavior()))
    return this.toString$0$bailout(2, sb, t1);
  var actualParameters = sb.toString$0();
  sb = $.StringBufferImpl$('');
  for (i = 0; i < t1.length; ++i) {
    if (i > 0)
      sb.add$1(', ');
    if (i < 0 || i >= t1.length)
      throw $.ioore(i);
    sb.add$1(t1[i]);
  }
  var formalParameters = sb.toString$0();
  t1 = this._functionName;
  return 'NoSuchMethodException: incorrect number of arguments passed to method named \'' + $.S(t1) + '\'\nReceiver: ' + $.S(this._receiver) + '\n' + 'Tried calling: ' + $.S(t1) + '(' + $.S(actualParameters) + ')\n' + 'Found: ' + $.S(t1) + '(' + $.S(formalParameters) + ')';
},
 toString$0$bailout: function(state, env0, env1) {
  switch (state) {
    case 1:
      t1 = env0;
      sb = env1;
      break;
    case 2:
      sb = env0;
      t1 = env1;
      break;
  }
  switch (state) {
    case 0:
      var sb = $.StringBufferImpl$('');
      var t1 = this._arguments;
    case 1:
      state = 0;
      var i = 0;
      for (; $.ltB(i, $.get$length(t1)); ++i) {
        if (i > 0)
          sb.add$1(', ');
        sb.add$1($.index(t1, i));
      }
      t1 = this._existingArgumentNames;
    case 2:
      state = 0;
      if (t1 == null)
        return 'NoSuchMethodException : method not found: \'' + $.S(this._functionName) + '\'\n' + 'Receiver: ' + $.S(this._receiver) + '\n' + 'Arguments: [' + $.S(sb) + ']';
      else {
        var actualParameters = sb.toString$0();
        sb = $.StringBufferImpl$('');
        for (i = 0; $.ltB(i, $.get$length(t1)); ++i) {
          if (i > 0)
            sb.add$1(', ');
          sb.add$1($.index(t1, i));
        }
        var formalParameters = sb.toString$0();
        t1 = this._functionName;
        return 'NoSuchMethodException: incorrect number of arguments passed to method named \'' + $.S(t1) + '\'\nReceiver: ' + $.S(this._receiver) + '\n' + 'Tried calling: ' + $.S(t1) + '(' + $.S(actualParameters) + ')\n' + 'Found: ' + $.S(t1) + '(' + $.S(formalParameters) + ')';
      }
  }
}
};

$$.ObjectNotClosureException = {"":
 [],
 super: "Object",
 toString$0: function() {
  return 'Object is not closure';
}
};

$$.IllegalArgumentException = {"":
 ["_arg"],
 super: "Object",
 toString$0: function() {
  return 'Illegal argument(s): ' + $.S(this._arg);
}
};

$$.StackOverflowException = {"":
 [],
 super: "Object",
 toString$0: function() {
  return 'Stack Overflow';
}
};

$$.NullPointerException = {"":
 ["functionName", "arguments"],
 super: "Object",
 toString$0: function() {
  var t1 = this.functionName;
  if (t1 == null)
    return this.get$exceptionName();
  else
    return $.S(this.get$exceptionName()) + ' : method: \'' + $.S(t1) + '\'\n' + 'Receiver: null\n' + 'Arguments: ' + $.S(this.arguments);
},
 get$exceptionName: function() {
  return 'NullPointerException';
}
};

$$.NoMoreElementsException = {"":
 [],
 super: "Object",
 toString$0: function() {
  return 'NoMoreElementsException';
}
};

$$.EmptyQueueException = {"":
 [],
 super: "Object",
 toString$0: function() {
  return 'EmptyQueueException';
}
};

$$.UnsupportedOperationException = {"":
 ["_message"],
 super: "Object",
 toString$0: function() {
  return 'UnsupportedOperationException: ' + $.S(this._message);
}
};

$$.NotImplementedException = {"":
 ["_message"],
 super: "Object",
 toString$0: function() {
  var t1 = this._message;
  return !(t1 == null) ? 'NotImplementedException: ' + $.S(t1) : 'NotImplementedException';
}
};

$$.IllegalJSRegExpException = {"":
 ["_pattern", "_errmsg"],
 super: "Object",
 toString$0: function() {
  return 'IllegalJSRegExpException: \'' + $.S(this._pattern) + '\' \'' + $.S(this._errmsg) + '\'';
}
};

$$.Object = {"":
 [],
 super: "",
 toString$0: function() {
  return $.ObjectImplementation_toStringImpl(this);
},
 operator$eq$1: function(other) {
  return this === other;
}
};

$$.ListIterator = {"":
 ["i", "list"],
 super: "Object",
 hasNext$0: function() {
  var t1 = this.i;
  if (typeof t1 !== 'number')
    return this.hasNext$0$bailout(1, t1);
  return t1 < this.list.length;
},
 hasNext$0$bailout: function(state, t1) {
  return $.lt(t1, this.list.length);
},
 next$0: function() {
  if (this.hasNext$0() !== true)
    throw $.captureStackTrace($.NoMoreElementsException$());
  var value = this.list[this.i];
  var t1 = this.i;
  if (typeof t1 !== 'number')
    return this.next$0$bailout(1, t1, value);
  this.i = t1 + 1;
  return value;
},
 next$0$bailout: function(state, t1, value) {
  this.i = $.add(t1, 1);
  return value;
}
};

$$.Closure = {"":
 [],
 super: "Object",
 toString$0: function() {
  return 'Closure';
}
};

$$.ConstantMap = {"":
 ["length?", "_jsObject", "_lib1_keys?"],
 super: "Object",
 containsKey$1: function(key) {
  if ($.eqB(key, '__proto__'))
    return false;
  return $.jsHasOwnProperty(this._jsObject, key);
},
 operator$index$1: function(key) {
  if (this.containsKey$1(key) !== true)
    return;
  return this._jsObject[key];
},
 forEach$1: function(f) {
  $.forEach(this._lib1_keys, new $.ConstantMap_forEach_anon(this, f));
},
 getValues$0: function() {
  var result = [];
  $.forEach(this._lib1_keys, new $.ConstantMap_getValues_anon(this, result));
  return result;
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 toString$0: function() {
  return $.Maps_mapToString(this);
},
 _throwImmutable$0: function() {
  throw $.captureStackTrace($.CTC20);
},
 operator$indexSet$2: function(key, val) {
  return this._throwImmutable$0();
},
 clear$0: function() {
  return this._throwImmutable$0();
},
 is$Map: function() { return true; }
};

$$.MetaInfo = {"":
 ["_tag?", "_tags", "_set?"],
 super: "Object"
};

$$.FancyDivElement = {"":
 ["_root?", "_idiomCount"],
 super: "DivElementImpl",
 created$1: function(root) {
  this._root = root;
  this._idiomCount = 0;
},
 inserted$0: function() {
  $.add$1(this._root.get$on().get$click(), new $.FancyDivElement_inserted_anon(this));
  $.print('[samhop] NotAWrapper inserted');
},
 attributeChanged$3: function(name$, oldValue, newValue) {
},
 removed$0: function() {
},
 generateIdiom$0: function() {
  this._idiomCount = $.add(this._idiomCount, 1);
  if ($.gtB(this._idiomCount, 2))
    this._idiomCount = 0;
  switch (this._idiomCount) {
    case 0:
      return 'When it rains, it pours!';
    case 1:
      return 'There\'s no such thing as bad publicity.';
    case 2:
      return 'I don\'t think we\'re in Kansas anymore, Toto.';
  }
},
 is$WebComponent: function() { return true; }
};

$$._Default = {"":
 [],
 super: "Object"
};

$$.AbstractWorkerEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.AudioContextEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl"
};

$$.BatteryManagerEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl"
};

$$.BodyElementEventsImpl = {"":
 ["_ptr"],
 super: "ElementEventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.DOMApplicationCacheEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.DedicatedWorkerContextEventsImpl = {"":
 ["_ptr"],
 super: "WorkerContextEventsImpl"
};

$$.DocumentEventsImpl = {"":
 ["_ptr"],
 super: "ElementEventsImpl",
 get$click: function() {
  return this.operator$index$1('click');
},
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); },
 get$readyStateChange: function() {
  return this.operator$index$1('readystatechange');
}
};

$$.FilteredElementList = {"":
 ["_node", "_childNodes"],
 super: "Object",
 get$_filtered: function() {
  return $.ListImplementation_List$from($.filter(this._childNodes, new $.FilteredElementList__filtered_anon()));
},
 get$first: function() {
  for (var t1 = $.iterator(this._childNodes); t1.hasNext$0() === true;) {
    var t2 = t1.next$0();
    if (typeof t2 === 'object' && t2 !== null && t2.is$Element())
      return t2;
  }
  return;
},
 first$0: function() { return this.get$first().call$0(); },
 forEach$1: function(f) {
  $.forEach(this.get$_filtered(), f);
},
 operator$indexSet$2: function(index, value) {
  this.operator$index$1(index).replaceWith$1(value);
},
 set$length: function(newLength) {
  var len = $.get$length(this);
  if ($.geB(newLength, len))
    return;
  else if ($.ltB(newLength, 0))
    throw $.captureStackTrace($.CTC17);
  this.removeRange$2($.sub(newLength, 1), $.sub(len, newLength));
},
 add$1: function(value) {
  $.add$1(this._childNodes, value);
},
 get$add: function() { return new $.BoundClosure0(this, 'add$1'); },
 addAll$1: function(collection) {
  $.forEach(collection, this.get$add());
},
 addLast$1: function(value) {
  this.add$1(value);
},
 removeRange$2: function(start, rangeLength) {
  $.forEach($.getRange(this.get$_filtered(), start, rangeLength), new $.FilteredElementList_removeRange_anon());
},
 clear$0: function() {
  $.clear(this._childNodes);
},
 removeLast$0: function() {
  var result = this.last$0();
  if (!(result == null))
    result.remove$0();
  return result;
},
 filter$1: function(f) {
  return $.filter(this.get$_filtered(), f);
},
 isEmpty$0: function() {
  return $.isEmpty(this.get$_filtered());
},
 get$length: function() {
  return $.get$length(this.get$_filtered());
},
 operator$index$1: function(index) {
  return $.index(this.get$_filtered(), index);
},
 iterator$0: function() {
  return $.iterator(this.get$_filtered());
},
 getRange$2: function(start, rangeLength) {
  return $.getRange(this.get$_filtered(), start, rangeLength);
},
 last$0: function() {
  return $.last(this.get$_filtered());
},
 is$List: function() { return true; },
 is$Collection: function() { return true; }
};

$$._FrozenCSSClassSet = {"":
 ["_lib_element"],
 super: "_CssClassSet",
 _write$1: function(s) {
  throw $.captureStackTrace($.CTC18);
},
 _read$0: function() {
  return $.HashSetImplementation$('String');
}
};

$$._ChildrenElementList = {"":
 ["_lib_element?", "_childElements"],
 super: "Object",
 _toList$0: function() {
  var t1 = this._childElements;
  if (typeof t1 !== 'string' && (typeof t1 !== 'object' || t1 === null || t1.constructor !== Array && !t1.is$JavaScriptIndexingBehavior()))
    return this._toList$0$bailout(1, t1);
  var output = $.ListImplementation_List(t1.length);
  for (var len = t1.length, i = 0; i < len; ++i) {
    if (i < 0 || i >= t1.length)
      throw $.ioore(i);
    var t2 = t1[i];
    if (i < 0 || i >= output.length)
      throw $.ioore(i);
    output[i] = t2;
  }
  return output;
},
 _toList$0$bailout: function(state, t1) {
  var output = $.ListImplementation_List($.get$length(t1));
  for (var len = $.get$length(t1), i = 0; $.ltB(i, len); ++i) {
    var t2 = $.index(t1, i);
    if (i < 0 || i >= output.length)
      throw $.ioore(i);
    output[i] = t2;
  }
  return output;
},
 get$first: function() {
  return this._lib_element.get$$$dom_firstElementChild();
},
 first$0: function() { return this.get$first().call$0(); },
 forEach$1: function(f) {
  for (var t1 = $.iterator(this._childElements); t1.hasNext$0() === true;)
    f.call$1(t1.next$0());
},
 filter$1: function(f) {
  var output = [];
  this.forEach$1(new $._ChildrenElementList_filter_anon(f, output));
  return $._FrozenElementList$_wrap(output);
},
 isEmpty$0: function() {
  return this._lib_element.get$$$dom_firstElementChild() == null;
},
 get$length: function() {
  return $.get$length(this._childElements);
},
 operator$index$1: function(index) {
  return $.index(this._childElements, index);
},
 operator$indexSet$2: function(index, value) {
  this._lib_element.$dom_replaceChild$2(value, $.index(this._childElements, index));
},
 set$length: function(newLength) {
  throw $.captureStackTrace($.CTC16);
},
 add$1: function(value) {
  this._lib_element.$dom_appendChild$1(value);
  return value;
},
 addLast$1: function(value) {
  return this.add$1(value);
},
 iterator$0: function() {
  return $.iterator(this._toList$0());
},
 addAll$1: function(collection) {
  for (var t1 = $.iterator(collection), t2 = this._lib_element; t1.hasNext$0() === true;)
    t2.$dom_appendChild$1(t1.next$0());
},
 getRange$2: function(start, rangeLength) {
  return $._FrozenElementList$_wrap($._Lists_getRange(this, start, rangeLength, []));
},
 clear$0: function() {
  this._lib_element.set$text('');
},
 removeLast$0: function() {
  var result = this.last$0();
  if (!(result == null))
    this._lib_element.$dom_removeChild$1(result);
  return result;
},
 last$0: function() {
  return this._lib_element.get$$$dom_lastElementChild();
},
 is$List: function() { return true; },
 is$Collection: function() { return true; }
};

$$._FrozenElementList = {"":
 ["_nodeList"],
 super: "Object",
 get$first: function() {
  return $.index(this._nodeList, 0);
},
 first$0: function() { return this.get$first().call$0(); },
 forEach$1: function(f) {
  for (var t1 = $.iterator(this); t1.hasNext$0() === true;)
    f.call$1(t1.next$0());
},
 filter$1: function(f) {
  var out = $._ElementList$([]);
  for (var t1 = $.iterator(this); t1.hasNext$0() === true;) {
    var t2 = t1.next$0();
    if (f.call$1(t2) === true)
      out.add$1(t2);
  }
  return out;
},
 isEmpty$0: function() {
  return $.isEmpty(this._nodeList);
},
 get$length: function() {
  return $.get$length(this._nodeList);
},
 operator$index$1: function(index) {
  return $.index(this._nodeList, index);
},
 operator$indexSet$2: function(index, value) {
  throw $.captureStackTrace($.CTC16);
},
 set$length: function(newLength) {
  $.set$length(this._nodeList, newLength);
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC16);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC16);
},
 iterator$0: function() {
  return $._FrozenElementListIterator$(this);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC16);
},
 getRange$2: function(start, rangeLength) {
  return $._FrozenElementList$_wrap($.getRange(this._nodeList, start, rangeLength));
},
 clear$0: function() {
  throw $.captureStackTrace($.CTC16);
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC16);
},
 last$0: function() {
  return $.last(this._nodeList);
},
 is$List: function() { return true; },
 is$Collection: function() { return true; }
};

$$._FrozenElementListIterator = {"":
 ["_lib_list", "_index"],
 super: "Object",
 next$0: function() {
  if (this.hasNext$0() !== true)
    throw $.captureStackTrace($.CTC12);
  var t1 = this._lib_list;
  if (typeof t1 !== 'string' && (typeof t1 !== 'object' || t1 === null || t1.constructor !== Array && !t1.is$JavaScriptIndexingBehavior()))
    return this.next$0$bailout(1, t1, 0);
  var t3 = this._index;
  if (typeof t3 !== 'number')
    return this.next$0$bailout(2, t1, t3);
  this._index = t3 + 1;
  if (t3 !== (t3 | 0))
    throw $.iae(t3);
  if (t3 < 0 || t3 >= t1.length)
    throw $.ioore(t3);
  return t1[t3];
},
 next$0$bailout: function(state, env0, env1) {
  switch (state) {
    case 1:
      t1 = env0;
      break;
    case 2:
      t1 = env0;
      t3 = env1;
      break;
  }
  switch (state) {
    case 0:
      if (this.hasNext$0() !== true)
        throw $.captureStackTrace($.CTC12);
      var t1 = this._lib_list;
    case 1:
      state = 0;
      var t3 = this._index;
    case 2:
      state = 0;
      this._index = $.add(t3, 1);
      return $.index(t1, t3);
  }
},
 hasNext$0: function() {
  var t1 = this._index;
  if (typeof t1 !== 'number')
    return this.hasNext$0$bailout(1, t1, 0);
  var t3 = $.get$length(this._lib_list);
  if (typeof t3 !== 'number')
    return this.hasNext$0$bailout(2, t1, t3);
  return t1 < t3;
},
 hasNext$0$bailout: function(state, env0, env1) {
  switch (state) {
    case 1:
      t1 = env0;
      break;
    case 2:
      t1 = env0;
      t3 = env1;
      break;
  }
  switch (state) {
    case 0:
      var t1 = this._index;
    case 1:
      state = 0;
      var t3 = $.get$length(this._lib_list);
    case 2:
      state = 0;
      return $.lt(t1, t3);
  }
}
};

$$._ElementList = {"":
 ["_lib_list"],
 super: "_ListWrapper",
 filter$1: function(f) {
  return $._ElementList$($._ListWrapper.prototype.filter$1.call(this, f));
},
 getRange$2: function(start, rangeLength) {
  return $._ElementList$($._ListWrapper.prototype.getRange$2.call(this, start, rangeLength));
},
 is$List: function() { return true; },
 is$Collection: function() { return true; }
};

$$._ElementAttributeMap = {"":
 ["_lib_element?"],
 super: "Object",
 containsKey$1: function(key) {
  return this._lib_element.$dom_hasAttribute$1(key);
},
 operator$index$1: function(key) {
  return this._lib_element.$dom_getAttribute$1(key);
},
 operator$indexSet$2: function(key, value) {
  this._lib_element.$dom_setAttribute$2(key, $.S(value));
},
 remove$1: function(key) {
  var t1 = this._lib_element;
  var value = t1.$dom_getAttribute$1(key);
  t1.$dom_removeAttribute$1(key);
  return value;
},
 clear$0: function() {
  var attributes = this._lib_element.get$$$dom_attributes();
  if (typeof attributes !== 'string' && (typeof attributes !== 'object' || attributes === null || attributes.constructor !== Array && !attributes.is$JavaScriptIndexingBehavior()))
    return this.clear$0$bailout(1, attributes);
  for (var i = attributes.length - 1; i >= 0; --i) {
    if (i < 0 || i >= attributes.length)
      throw $.ioore(i);
    this.remove$1(attributes[i].get$name());
  }
},
 clear$0$bailout: function(state, attributes) {
  for (var i = $.sub($.get$length(attributes), 1); $.geB(i, 0); i = $.sub(i, 1))
    this.remove$1($.index(attributes, i).get$name());
},
 forEach$1: function(f) {
  var attributes = this._lib_element.get$$$dom_attributes();
  if (typeof attributes !== 'string' && (typeof attributes !== 'object' || attributes === null || attributes.constructor !== Array && !attributes.is$JavaScriptIndexingBehavior()))
    return this.forEach$1$bailout(1, f, attributes);
  for (var len = attributes.length, i = 0; i < len; ++i) {
    if (i < 0 || i >= attributes.length)
      throw $.ioore(i);
    var item = attributes[i];
    f.call$2(item.get$name(), item.get$value());
  }
},
 forEach$1$bailout: function(state, f, attributes) {
  for (var len = $.get$length(attributes), i = 0; $.ltB(i, len); ++i) {
    var item = $.index(attributes, i);
    f.call$2(item.get$name(), item.get$value());
  }
},
 getValues$0: function() {
  var attributes = this._lib_element.get$$$dom_attributes();
  if (typeof attributes !== 'string' && (typeof attributes !== 'object' || attributes === null || attributes.constructor !== Array && !attributes.is$JavaScriptIndexingBehavior()))
    return this.getValues$0$bailout(1, attributes);
  var values = $.ListImplementation_List(attributes.length, 'String');
  for (var len = attributes.length, i = 0; i < len; ++i) {
    if (i < 0 || i >= attributes.length)
      throw $.ioore(i);
    var t1 = attributes[i].get$value();
    if (i < 0 || i >= values.length)
      throw $.ioore(i);
    values[i] = t1;
  }
  return values;
},
 getValues$0$bailout: function(state, attributes) {
  var values = $.ListImplementation_List($.get$length(attributes), 'String');
  for (var len = $.get$length(attributes), i = 0; $.ltB(i, len); ++i) {
    var t1 = $.index(attributes, i).get$value();
    if (i < 0 || i >= values.length)
      throw $.ioore(i);
    values[i] = t1;
  }
  return values;
},
 get$length: function() {
  return $.get$length(this._lib_element.get$$$dom_attributes());
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 is$Map: function() { return true; }
};

$$._CssClassSet = {"":
 ["_lib_element?"],
 super: "Object",
 toString$0: function() {
  return this._formatSet$1(this._read$0());
},
 iterator$0: function() {
  return $.iterator(this._read$0());
},
 forEach$1: function(f) {
  $.forEach(this._read$0(), f);
},
 filter$1: function(f) {
  return $.filter(this._read$0(), f);
},
 isEmpty$0: function() {
  return $.isEmpty(this._read$0());
},
 get$length: function() {
  return $.get$length(this._read$0());
},
 add$1: function(value) {
  this._modify$1(new $._CssClassSet_add_anon(value));
},
 addAll$1: function(collection) {
  this._modify$1(new $._CssClassSet_addAll_anon(collection));
},
 clear$0: function() {
  this._modify$1(new $._CssClassSet_clear_anon());
},
 _modify$1: function(f) {
  var s = this._read$0();
  f.call$1(s);
  this._write$1(s);
},
 _read$0: function() {
  var s = $.HashSetImplementation$('String');
  for (var t1 = $.iterator($.split(this._classname$0(), ' ')); t1.hasNext$0() === true;) {
    var trimmed = $.trim(t1.next$0());
    if ($.isEmpty(trimmed) !== true)
      s.add$1(trimmed);
  }
  return s;
},
 _classname$0: function() {
  return this._lib_element.get$$$dom_className();
},
 _write$1: function(s) {
  var t1 = this._formatSet$1(s);
  this._lib_element.set$$$dom_className(t1);
},
 _formatSet$1: function(s) {
  return $.Strings_join($.ListImplementation_List$from(s), ' ');
},
 is$Collection: function() { return true; }
};

$$.ElementEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$click: function() {
  return this.operator$index$1('click');
},
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.EventSourceEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); },
 get$open: function() {
  return this.operator$index$1('open');
},
 open$3$async: function(arg0, arg1, arg2) { return this.get$open().call$3$async(arg0, arg1, arg2); }
};

$$.EventsImpl = {"":
 ["_ptr?"],
 super: "Object",
 operator$index$1: function(type) {
  return $.EventListenerListImpl$(this._ptr, type);
}
};

$$.EventListenerListImpl = {"":
 ["_ptr?", "_type"],
 super: "Object",
 add$2: function(listener, useCapture) {
  this._add$2(listener, useCapture);
  return this;
},
 add$1: function(listener) {
  return this.add$2(listener,false)
},
 _add$2: function(listener, useCapture) {
  this._ptr.$dom_addEventListener$3(this._type, listener, useCapture);
}
};

$$.FileReaderEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.FileWriterEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.FrameSetElementEventsImpl = {"":
 ["_ptr"],
 super: "ElementEventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.HttpRequestEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); },
 get$readyStateChange: function() {
  return this.operator$index$1('readystatechange');
}
};

$$.HttpRequestUploadEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.IDBDatabaseEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.IDBOpenDBRequestEventsImpl = {"":
 ["_ptr"],
 super: "IDBRequestEventsImpl"
};

$$.IDBRequestEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.IDBTransactionEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.IDBVersionChangeRequestEventsImpl = {"":
 ["_ptr"],
 super: "IDBRequestEventsImpl"
};

$$.InputElementEventsImpl = {"":
 ["_ptr"],
 super: "ElementEventsImpl"
};

$$.JavaScriptAudioNodeEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl"
};

$$.MediaElementEventsImpl = {"":
 ["_ptr"],
 super: "ElementEventsImpl"
};

$$.MediaStreamEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl"
};

$$.MediaStreamTrackEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl"
};

$$.MediaStreamTrackListEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl"
};

$$.MessagePortEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl"
};

$$._ChildNodeListLazy = {"":
 ["_this"],
 super: "Object",
 get$first: function() {
  return this._this.firstChild;
},
 first$0: function() { return this.get$first().call$0(); },
 last$0: function() {
  return this._this.lastChild;
},
 add$1: function(value) {
  this._this.$dom_appendChild$1(value);
},
 addLast$1: function(value) {
  this._this.$dom_appendChild$1(value);
},
 addAll$1: function(collection) {
  for (var t1 = $.iterator(collection), t2 = this._this; t1.hasNext$0() === true;)
    t2.$dom_appendChild$1(t1.next$0());
},
 removeLast$0: function() {
  var result = this.last$0();
  if (!(result == null))
    this._this.$dom_removeChild$1(result);
  return result;
},
 clear$0: function() {
  this._this.set$text('');
},
 operator$indexSet$2: function(index, value) {
  this._this.$dom_replaceChild$2(value, this.operator$index$1(index));
},
 iterator$0: function() {
  return $.iterator(this._this.get$$$dom_childNodes());
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._NodeListWrapper$($._Collections_filter(this, [], f));
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 getRange$2: function(start, rangeLength) {
  return $._NodeListWrapper$($._Lists_getRange(this, start, rangeLength, []));
},
 get$length: function() {
  return $.get$length(this._this.get$$$dom_childNodes());
},
 operator$index$1: function(index) {
  return $.index(this._this.get$$$dom_childNodes(), index);
},
 is$List: function() { return true; },
 is$Collection: function() { return true; }
};

$$._ListWrapper = {"":
 [],
 super: "Object",
 iterator$0: function() {
  return $.iterator(this._lib_list);
},
 forEach$1: function(f) {
  return $.forEach(this._lib_list, f);
},
 filter$1: function(f) {
  return $.filter(this._lib_list, f);
},
 isEmpty$0: function() {
  return $.isEmpty(this._lib_list);
},
 get$length: function() {
  return $.get$length(this._lib_list);
},
 operator$index$1: function(index) {
  return $.index(this._lib_list, index);
},
 operator$indexSet$2: function(index, value) {
  $.indexSet(this._lib_list, index, value);
},
 set$length: function(newLength) {
  $.set$length(this._lib_list, newLength);
},
 add$1: function(value) {
  return $.add$1(this._lib_list, value);
},
 addLast$1: function(value) {
  return $.addLast(this._lib_list, value);
},
 addAll$1: function(collection) {
  return $.addAll(this._lib_list, collection);
},
 clear$0: function() {
  return $.clear(this._lib_list);
},
 removeLast$0: function() {
  return $.removeLast(this._lib_list);
},
 last$0: function() {
  return $.last(this._lib_list);
},
 getRange$2: function(start, rangeLength) {
  return $.getRange(this._lib_list, start, rangeLength);
},
 get$first: function() {
  return $.index(this._lib_list, 0);
},
 first$0: function() { return this.get$first().call$0(); },
 is$List: function() { return true; },
 is$Collection: function() { return true; }
};

$$._NodeListWrapper = {"":
 ["_lib_list"],
 super: "_ListWrapper",
 filter$1: function(f) {
  return $._NodeListWrapper$($.filter(this._lib_list, f));
},
 getRange$2: function(start, rangeLength) {
  return $._NodeListWrapper$($.getRange(this._lib_list, start, rangeLength));
},
 is$List: function() { return true; },
 is$Collection: function() { return true; }
};

$$.NotificationEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$click: function() {
  return this.operator$index$1('click');
},
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.PeerConnection00EventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$open: function() {
  return this.operator$index$1('open');
},
 open$3$async: function(arg0, arg1, arg2) { return this.get$open().call$3$async(arg0, arg1, arg2); }
};

$$._AttributeClassSet = {"":
 ["_lib_element"],
 super: "_CssClassSet",
 $dom_className$0: function() {
  return $.index(this._lib_element.get$attributes(), 'class');
},
 get$$$dom_className: function() { return new $.BoundClosure(this, '$dom_className$0'); },
 _write$1: function(s) {
  $.indexSet(this._lib_element.get$attributes(), 'class', this._formatSet$1(s));
}
};

$$.SVGElementInstanceEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$click: function() {
  return this.operator$index$1('click');
},
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.SharedWorkerContextEventsImpl = {"":
 ["_ptr"],
 super: "WorkerContextEventsImpl"
};

$$.SpeechRecognitionEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.TextTrackEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl"
};

$$.TextTrackCueEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl"
};

$$.TextTrackListEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl"
};

$$.WebSocketEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); },
 get$open: function() {
  return this.operator$index$1('open');
},
 open$3$async: function(arg0, arg1, arg2) { return this.get$open().call$3$async(arg0, arg1, arg2); }
};

$$.WindowEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$click: function() {
  return this.operator$index$1('click');
},
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$.WorkerEventsImpl = {"":
 ["_ptr"],
 super: "AbstractWorkerEventsImpl"
};

$$.WorkerContextEventsImpl = {"":
 ["_ptr"],
 super: "EventsImpl",
 get$error: function() {
  return this.operator$index$1('error');
},
 error$1: function(arg0) { return this.get$error().call$1(arg0); }
};

$$._FixedSizeListIterator = {"":
 ["_lib_length", "_array", "_pos"],
 super: "_VariableSizeListIterator",
 hasNext$0: function() {
  var t1 = this._lib_length;
  if (typeof t1 !== 'number')
    return this.hasNext$0$bailout(1, t1, 0);
  var t3 = this._pos;
  if (typeof t3 !== 'number')
    return this.hasNext$0$bailout(2, t1, t3);
  return t1 > t3;
},
 hasNext$0$bailout: function(state, env0, env1) {
  switch (state) {
    case 1:
      t1 = env0;
      break;
    case 2:
      t1 = env0;
      t3 = env1;
      break;
  }
  switch (state) {
    case 0:
      var t1 = this._lib_length;
    case 1:
      state = 0;
      var t3 = this._pos;
    case 2:
      state = 0;
      return $.gt(t1, t3);
  }
}
};

$$._VariableSizeListIterator = {"":
 [],
 super: "Object",
 hasNext$0: function() {
  var t1 = $.get$length(this._array);
  if (typeof t1 !== 'number')
    return this.hasNext$0$bailout(1, t1, 0);
  var t3 = this._pos;
  if (typeof t3 !== 'number')
    return this.hasNext$0$bailout(2, t3, t1);
  return t1 > t3;
},
 hasNext$0$bailout: function(state, env0, env1) {
  switch (state) {
    case 1:
      t1 = env0;
      break;
    case 2:
      t3 = env0;
      t1 = env1;
      break;
  }
  switch (state) {
    case 0:
      var t1 = $.get$length(this._array);
    case 1:
      state = 0;
      var t3 = this._pos;
    case 2:
      state = 0;
      return $.gt(t1, t3);
  }
},
 next$0: function() {
  if (this.hasNext$0() !== true)
    throw $.captureStackTrace($.CTC12);
  var t1 = this._array;
  if (typeof t1 !== 'string' && (typeof t1 !== 'object' || t1 === null || t1.constructor !== Array && !t1.is$JavaScriptIndexingBehavior()))
    return this.next$0$bailout(1, t1, 0);
  var t3 = this._pos;
  if (typeof t3 !== 'number')
    return this.next$0$bailout(2, t1, t3);
  this._pos = t3 + 1;
  if (t3 !== (t3 | 0))
    throw $.iae(t3);
  if (t3 < 0 || t3 >= t1.length)
    throw $.ioore(t3);
  return t1[t3];
},
 next$0$bailout: function(state, env0, env1) {
  switch (state) {
    case 1:
      t1 = env0;
      break;
    case 2:
      t1 = env0;
      t3 = env1;
      break;
  }
  switch (state) {
    case 0:
      if (this.hasNext$0() !== true)
        throw $.captureStackTrace($.CTC12);
      var t1 = this._array;
    case 1:
      state = 0;
      var t3 = this._pos;
    case 2:
      state = 0;
      this._pos = $.add(t3, 1);
      return $.index(t1, t3);
  }
}
};

$$._ProtoTester = {"":
 ["f?"],
 super: "Object"
};

$$.CustomElementsManager = {"":
 ["_customDeclarations?", "_customElements?", "_lookup", "_insertionObserver"],
 super: "Object",
 _lookup$1: function(arg0) { return this._lookup.call$1(arg0); },
 _loadComponents$0: function() {
  $.forEach($.queryAll('link[rel=components]'), new $.CustomElementsManager__loadComponents_anon(this));
  this._expandDeclarations$0();
},
 _load$1: function(url) {
  var request = $._HttpRequestFactoryProvider_HttpRequest();
  request.open$3$async('GET', url, false);
  $.add$1(request.get$on().get$readyStateChange(), new $.CustomElementsManager__load_anon(this, request));
  request.send$0();
},
 _parse$1: function(toParse) {
  var declarations = $._DocumentFragmentFactoryProvider_DocumentFragment$html(toParse);
  var newDeclarations = [];
  $.forEach(declarations.queryAll$1('element'), new $.CustomElementsManager__parse_anon(newDeclarations));
  return newDeclarations;
},
 _expandDeclarations$2: function(root, insert) {
  var newCustomElements = [];
  var t1 = root == null;
  if (t1) {
    var target = $.document();
    var rootUnderTemplate = false;
  } else {
    rootUnderTemplate = root.matchesSelector$1('template *');
    if (typeof rootUnderTemplate !== 'boolean')
      return this._expandDeclarations$2$bailout(1, root, insert, rootUnderTemplate, newCustomElements, t1, 0, 0, 0);
    target = root;
  }
  var t2 = $.iterator(this._customDeclarations.getValues$0());
  t1 = !t1;
  var t3 = !rootUnderTemplate;
  var t4 = this._customElements;
  if (typeof t4 !== 'string' && (typeof t4 !== 'object' || t4 === null || t4.constructor !== Array && !t4.is$JavaScriptIndexingBehavior()))
    return this._expandDeclarations$2$bailout(2, t4, root, target, t3, newCustomElements, insert, t2, t1);
  var t6 = insert === true;
  for (; t2.hasNext$0() === true;) {
    var t5 = t2.next$0();
    var selector = $.S(t5.get$extendz()) + '[is=' + $.S(t5.get$name()) + ']';
    var activeElements = $.filter(target.queryAll$1(selector), new $.CustomElementsManager__expandDeclarations_anon());
    if (t1 && root.matchesSelector$1(selector) === true && t3)
      $.add$1(activeElements, root);
    for (var t7 = $.iterator(activeElements); t7.hasNext$0() === true;) {
      var component = t7.next$0();
      if ($._usePrototypeRewiring !== true) {
        if (component !== (component | 0))
          throw $.iae(component);
        if (component < 0 || component >= t4.length)
          throw $.ioore(component);
        var component0 = t4[component];
        if (component0 == null) {
          component = t5.morph$1(component);
          newCustomElements.push(component);
        } else
          component = component0;
      } else if (!(typeof component === 'object' && component !== null && component.is$WebComponent())) {
        component0 = t5.morph$1(component);
        component.get$parent().$dom_replaceChild$2(component0, component);
        for (var t8 = $.iterator(component.get$nodes()); t8.hasNext$0() === true;) {
          var t9 = t8.next$0();
          $.add$1(component0.get$nodes(), t9.clone$1(true));
        }
        component0.set$classes(component.get$classes());
        component = component0;
      }
      if (t6)
        component.inserted$0();
    }
  }
  return newCustomElements;
},
 _expandDeclarations$2$bailout: function(state, env0, env1, env2, env3, env4, env5, env6, env7) {
  switch (state) {
    case 1:
      var root = env0;
      var insert = env1;
      rootUnderTemplate = env2;
      newCustomElements = env3;
      t1 = env4;
      break;
    case 2:
      t4 = env0;
      root = env1;
      target = env2;
      t3 = env3;
      newCustomElements = env4;
      insert = env5;
      t2 = env6;
      t1 = env7;
      break;
  }
  switch (state) {
    case 0:
      var newCustomElements = [];
      var t1 = root == null;
    case 1:
      if (state === 0 && t1) {
        var target = $.document();
        var rootUnderTemplate = false;
      } else
        switch (state) {
          case 0:
            rootUnderTemplate = root.matchesSelector$1('template *');
          case 1:
            state = 0;
            target = root;
        }
      var t2 = $.iterator(this._customDeclarations.getValues$0());
      t1 = !t1;
      var t3 = rootUnderTemplate !== true;
      var t4 = this._customElements;
    case 2:
      state = 0;
      var t6 = insert === true;
      for (; t2.hasNext$0() === true;) {
        var t5 = t2.next$0();
        var selector = $.S(t5.get$extendz()) + '[is=' + $.S(t5.get$name()) + ']';
        var activeElements = $.filter(target.queryAll$1(selector), new $.CustomElementsManager__expandDeclarations_anon());
        if (t1 && root.matchesSelector$1(selector) === true && t3)
          $.add$1(activeElements, root);
        for (var t7 = $.iterator(activeElements); t7.hasNext$0() === true;) {
          var component = t7.next$0();
          if ($._usePrototypeRewiring !== true) {
            var component0 = $.index(t4, component);
            if (component0 == null) {
              component = t5.morph$1(component);
              newCustomElements.push(component);
            } else
              component = component0;
          } else if (!(typeof component === 'object' && component !== null && component.is$WebComponent())) {
            component0 = t5.morph$1(component);
            component.get$parent().$dom_replaceChild$2(component0, component);
            for (var t8 = $.iterator(component.get$nodes()); t8.hasNext$0() === true;) {
              var t9 = t8.next$0();
              $.add$1(component0.get$nodes(), t9.clone$1(true));
            }
            component0.set$classes(component.get$classes());
            component = component0;
          }
          if (t6)
            component.inserted$0();
        }
      }
      return newCustomElements;
  }
},
 _expandDeclarations$0: function() {
  return this._expandDeclarations$2(null,true)
},
 _expandDeclarations$1: function(root) {
  return this._expandDeclarations$2(root,true)
},
 _expandDeclarations$2$insert: function(root,insert) {
  return this._expandDeclarations$2(root,insert)
},
 _removeComponents$1: function(root) {
  for (var t1 = $.iterator(this._customDeclarations.getValues$0()); t1.hasNext$0() === true;) {
    var t2 = t1.next$0();
    for (var t3 = $.iterator(root.queryAll$1($.S(t2.get$extendz()) + '[is=' + $.S(t2.get$name()) + ']')); t3.hasNext$0() === true;) {
      var component = this.operator$index$1(t3.next$0());
      if (typeof component === 'object' && component !== null && component.is$WebComponent())
        component.removed$0();
    }
    if (root.matchesSelector$1($.S(t2.get$extendz()) + '[is=' + $.S(t2.get$name()) + ']') === true) {
      component = this.operator$index$1(root);
      if (typeof component === 'object' && component !== null && component.is$WebComponent())
        component.removed$0();
    }
  }
},
 operator$index$1: function(element) {
  if ($._usePrototypeRewiring === true)
    var t1 = element;
  else {
    t1 = this._customElements;
    if (typeof t1 !== 'string' && (typeof t1 !== 'object' || t1 === null || t1.constructor !== Array && !t1.is$JavaScriptIndexingBehavior()))
      return this.operator$index$1$bailout(1, element, t1);
    if (element !== (element | 0))
      throw $.iae(element);
    if (element < 0 || element >= t1.length)
      throw $.ioore(element);
    t1 = t1[element];
  }
  return t1;
},
 operator$index$1$bailout: function(state, env0, env1) {
  switch (state) {
    case 1:
      var element = env0;
      t1 = env1;
      break;
  }
  switch (state) {
    case 0:
    case 1:
      if (state === 0 && $._usePrototypeRewiring === true)
        var t1 = element;
      else
        switch (state) {
          case 0:
            t1 = this._customElements;
          case 1:
            state = 0;
            t1 = $.index(t1, element);
        }
      return t1;
  }
},
 initializeInsertedRemovedCallbacks$1: function(root) {
  this._insertionObserver = $._MutationObserverFactoryProvider_MutationObserver(new $.CustomElementsManager_initializeInsertedRemovedCallbacks_anon(this));
  this._insertionObserver.observe$3$childList$subtree(root, true, true);
},
 CustomElementsManager$_internal$1: function(_lookup) {
  this._customDeclarations = $.makeLiteralMap([]);
  if ($._usePrototypeRewiring !== true)
    this._customElements = $.ListMap$('Element', 'WebComponent');
  this.initializeInsertedRemovedCallbacks$1($.document());
}
};

$$._CustomDeclaration = {"":
 ["name?", "extendz?", "template", "applyAuthorStyles!"],
 super: "Object",
 hashCode$0: function() {
  return $.hashCode(this.name);
},
 operator$eq$1: function(other) {
  if (!(typeof other === 'object' && other !== null && !!other.is$_CustomDeclaration))
    return false;
  else
    return $.eqB(other.name, this.name) && $.eqB(other.extendz, this.extendz) && $.eqB(other.template, this.template);
},
 morph$1: function(e) {
  var t1 = {};
  var t2 = this.template;
  if (t2 == null)
    return;
  t1.shadowRoot_1 = null;
  var target = $._usePrototypeRewiring === true ? $.manager()._lookup$1(this.name).call$0() : e;
  if ($.hasShadowRoot() === true) {
    t1.shadowRoot_1 = $._ShadowRootFactoryProvider_ShadowRoot(target);
    t1.shadowRoot_1.set$resetStyleInheritance(false);
    if (this.applyAuthorStyles === true)
      t1.shadowRoot_1.set$applyAuthorStyles(true);
  } else {
    t1.shadowRoot_1 = e.query$1('.shadowroot');
    var t3 = t1.shadowRoot_1;
    if (!(t3 == null) && $.eqB(t3.get$parent(), e))
      t1.shadowRoot_1.remove$0();
    t1.shadowRoot_1 = $._ElementFactoryProvider_Element$html('<div class="shadowroot"></div>');
    $.add$1(target.get$nodes(), t1.shadowRoot_1);
  }
  $.forEach(t2.get$nodes(), new $._CustomDeclaration_morph_anon(t1));
  t1.newCustomElement_2 = null;
  if ($._usePrototypeRewiring !== true) {
    t1.newCustomElement_2 = $.manager()._lookup$1(this.name).call$0();
    t1.newCustomElement_2.set$element(e);
    t2 = $.manager().get$_customElements();
    if (typeof t2 !== 'object' || t2 === null || (t2.constructor !== Array || !!t2.immutable$list) && !t2.is$JavaScriptIndexingBehavior())
      return this.morph$1$bailout(1, e, t1, t2);
    var t4 = t1.newCustomElement_2;
    if (e !== (e | 0))
      throw $.iae(e);
    if (e < 0 || e >= t2.length)
      throw $.ioore(e);
    t2[e] = t4;
  } else
    t1.newCustomElement_2 = target;
  $.manager()._expandDeclarations$2$insert(t1.shadowRoot_1, false);
  t1.newCustomElement_2.created$1(t1.shadowRoot_1);
  $.manager()._expandDeclarations$2$insert(t1.shadowRoot_1, true);
  $._MutationObserverFactoryProvider_MutationObserver(new $._CustomDeclaration_morph_anon0(t1)).observe$3$attributeOldValue$attributes(e, true, true);
  $.manager().initializeInsertedRemovedCallbacks$1(t1.shadowRoot_1);
  return t1.newCustomElement_2;
},
 morph$1$bailout: function(state, env0, env1, env2) {
  switch (state) {
    case 1:
      var e = env0;
      t1 = env1;
      t2 = env2;
      break;
  }
  switch (state) {
    case 0:
      var t1 = {};
      var t2 = this.template;
      if (t2 == null)
        return;
      t1.shadowRoot_1 = null;
      var target = $._usePrototypeRewiring === true ? $.manager()._lookup$1(this.name).call$0() : e;
      if ($.hasShadowRoot() === true) {
        t1.shadowRoot_1 = $._ShadowRootFactoryProvider_ShadowRoot(target);
        t1.shadowRoot_1.set$resetStyleInheritance(false);
        if (this.applyAuthorStyles === true)
          t1.shadowRoot_1.set$applyAuthorStyles(true);
      } else {
        t1.shadowRoot_1 = e.query$1('.shadowroot');
        var t3 = t1.shadowRoot_1;
        if (!(t3 == null) && $.eqB(t3.get$parent(), e))
          t1.shadowRoot_1.remove$0();
        t1.shadowRoot_1 = $._ElementFactoryProvider_Element$html('<div class="shadowroot"></div>');
        $.add$1(target.get$nodes(), t1.shadowRoot_1);
      }
      $.forEach(t2.get$nodes(), new $._CustomDeclaration_morph_anon(t1));
      t1.newCustomElement_2 = null;
    case 1:
      if (state === 1 || state === 0 && $._usePrototypeRewiring !== true)
        switch (state) {
          case 0:
            t1.newCustomElement_2 = $.manager()._lookup$1(this.name).call$0();
            t1.newCustomElement_2.set$element(e);
            t2 = $.manager().get$_customElements();
          case 1:
            state = 0;
            $.indexSet(t2, e, t1.newCustomElement_2);
        }
      else
        t1.newCustomElement_2 = target;
      $.manager()._expandDeclarations$2$insert(t1.shadowRoot_1, false);
      t1.newCustomElement_2.created$1(t1.shadowRoot_1);
      $.manager()._expandDeclarations$2$insert(t1.shadowRoot_1, true);
      $._MutationObserverFactoryProvider_MutationObserver(new $._CustomDeclaration_morph_anon0(t1)).observe$3$attributeOldValue$attributes(e, true, true);
      $.manager().initializeInsertedRemovedCallbacks$1(t1.shadowRoot_1);
      return t1.newCustomElement_2;
  }
},
 _CustomDeclaration$1: function(element) {
  this.name = $.index(element.get$attributes(), 'name');
  this.applyAuthorStyles = element.get$attributes().containsKey$1('apply-author-styles');
  if (this.name == null) {
    $.window().get$console().error$1('name attribute is required');
    return;
  }
  this.extendz = $.index(element.get$attributes(), 'extends');
  var t1 = this.extendz;
  if (t1 == null || $.eqB($.get$length(t1), 0)) {
    $.window().get$console().error$1('extends attribute is required');
    return;
  }
  this.template = element.query$1('template');
},
 is$_CustomDeclaration: true
};

$$.ListMap = {"":
 ["_lib3_list"],
 super: "Object",
 operator$indexSet$2: function(key, value) {
  this._lib3_list.push($._Pair$(key, value, $.getRuntimeTypeInfo(this).K, $.getRuntimeTypeInfo(this).V));
},
 operator$index$1: function(key) {
  for (var t1 = $.iterator(this._lib3_list); t1.hasNext$0() === true;) {
    var t2 = t1.next$0();
    if ($.eqB(t2.get$_lib3_key(), key))
      return t2.get$_lib3_value();
  }
  return;
}
};

$$._Pair = {"":
 ["_lib3_key?", "_lib3_value?"],
 super: "Object"
};

$$._componentsSetup_anon0 = {"":
 [],
 super: "Closure",
 call$0: function() {
  return $.FancyDivElement_FancyDivElement$component();
}
};

$$._componentsSetup_anon = {"":
 ["map_0"],
 super: "Closure",
 call$1: function(name$) {
  return $.index(this.map_0, name$);
}
};

$$._convertDartToNative_PrepareForStructuredClone_findSlot = {"":
 ["copies_3", "values_2"],
 super: "Closure",
 call$1: function(value) {
  var length$ = $.get$length(this.values_2);
  if (typeof length$ !== 'number')
    return this.call$1$bailout(1, value, length$);
  for (var i = 0; i < length$; ++i) {
    var t1 = $.index(this.values_2, i);
    if (t1 == null ? value == null : t1 === value)
      return i;
  }
  $.add$1(this.values_2, value);
  $.add$1(this.copies_3, null);
  return length$;
},
 call$1$bailout: function(state, value, length$) {
  for (var i = 0; $.ltB(i, length$); ++i) {
    var t1 = $.index(this.values_2, i);
    if (t1 == null ? value == null : t1 === value)
      return i;
  }
  $.add$1(this.values_2, value);
  $.add$1(this.copies_3, null);
  return length$;
}
};

$$._convertDartToNative_PrepareForStructuredClone_readSlot = {"":
 ["copies_4"],
 super: "Closure",
 call$1: function(i) {
  return $.index(this.copies_4, i);
}
};

$$._convertDartToNative_PrepareForStructuredClone_writeSlot = {"":
 ["copies_5"],
 super: "Closure",
 call$2: function(i, x) {
  $.indexSet(this.copies_5, i, x);
}
};

$$._convertDartToNative_PrepareForStructuredClone_cleanupSlots = {"":
 [],
 super: "Closure",
 call$0: function() {
}
};

$$._convertDartToNative_PrepareForStructuredClone_walk = {"":
 ["findSlot_8", "readSlot_7", "writeSlot_6"],
 super: "Closure",
 call$1: function(e) {
  var t1 = {};
  if (e == null)
    return e;
  if (typeof e === 'boolean')
    return e;
  if (typeof e === 'number')
    return e;
  if (typeof e === 'string')
    return e;
  if (typeof e === 'object' && e !== null && !!e.is$Date)
    throw $.captureStackTrace($.CTC3);
  if (typeof e === 'object' && e !== null && !!e.is$RegExp)
    throw $.captureStackTrace($.CTC4);
  if (typeof e === 'object' && e !== null && e.is$FileImpl())
    return e;
  if (typeof e === 'object' && e !== null && e.is$File())
    throw $.captureStackTrace($.CTC5);
  if (typeof e === 'object' && e !== null && e.is$BlobImpl())
    return e;
  if (typeof e === 'object' && e !== null && e.is$Blob())
    throw $.captureStackTrace($.CTC6);
  if (typeof e === 'object' && e !== null && e.is$FileListImpl())
    return e;
  if (typeof e === 'object' && e !== null && e.is$FileList())
    throw $.captureStackTrace($.CTC7);
  if (typeof e === 'object' && e !== null && e.is$ImageDataImpl())
    return e;
  if (typeof e === 'object' && e !== null && e.is$ImageData())
    throw $.captureStackTrace($.CTC7);
  if (typeof e === 'object' && e !== null && e.is$ArrayBufferImpl())
    return e;
  if (typeof e === 'object' && e !== null && e.is$ArrayBuffer())
    throw $.captureStackTrace($.CTC8);
  if (typeof e === 'object' && e !== null && e.is$ArrayBufferViewImpl())
    return e;
  if (typeof e === 'object' && e !== null && e.is$ArrayBufferView())
    throw $.captureStackTrace($.CTC9);
  if (typeof e === 'object' && e !== null && e.is$Map()) {
    var slot = this.findSlot_8.call$1(e);
    t1.copy_1 = this.readSlot_7.call$1(slot);
    var t2 = t1.copy_1;
    if (!(t2 == null))
      return t2;
    t1.copy_1 = {};
    this.writeSlot_6.call$2(slot, t1.copy_1);
    e.forEach$1(new $._convertDartToNative_PrepareForStructuredClone_walk_anon(this, t1));
    return t1.copy_1;
  }
  if (typeof e === 'object' && e !== null && (e.constructor === Array || e.is$List())) {
    if (typeof e !== 'object' || e === null || (e.constructor !== Array || !!e.immutable$list) && !e.is$JavaScriptIndexingBehavior())
      return this.call$1$bailout(1, e, 0, 0, 0, 0, 0);
    var length$ = e.length;
    slot = this.findSlot_8.call$1(e);
    var copy = this.readSlot_7.call$1(slot);
    if (!(copy == null)) {
      if (true === copy) {
        copy = new Array(length$);
        this.writeSlot_6.call$2(slot, copy);
      }
      return copy;
    }
    if (e instanceof Array && !!!(e.immutable$list)) {
      this.writeSlot_6.call$2(slot, true);
      for (var i = 0; i < length$; ++i) {
        if (i < 0 || i >= e.length)
          throw $.ioore(i);
        var element = e[i];
        var elementCopy = this.call$1(element);
        if (!(elementCopy == null ? element == null : elementCopy === element)) {
          copy = this.readSlot_7.call$1(slot);
          if (true === copy) {
            copy = new Array(length$);
            this.writeSlot_6.call$2(slot, copy);
          }
          if (typeof copy !== 'object' || copy === null || (copy.constructor !== Array || !!copy.immutable$list) && !copy.is$JavaScriptIndexingBehavior())
            return this.call$1$bailout(2, copy, elementCopy, e, length$, i, slot);
          for (var j = 0; j < i; ++j) {
            if (j < 0 || j >= e.length)
              throw $.ioore(j);
            t1 = e[j];
            if (j < 0 || j >= copy.length)
              throw $.ioore(j);
            copy[j] = t1;
          }
          if (i < 0 || i >= copy.length)
            throw $.ioore(i);
          copy[i] = elementCopy;
          ++i;
          break;
        }
      }
      if (copy == null) {
        this.writeSlot_6.call$2(slot, e);
        copy = e;
      }
    } else {
      copy = new Array(length$);
      this.writeSlot_6.call$2(slot, copy);
      i = 0;
    }
    if (typeof copy !== 'object' || copy === null || (copy.constructor !== Array || !!copy.immutable$list) && !copy.is$JavaScriptIndexingBehavior())
      return this.call$1$bailout(3, i, copy, e, length$, 0, 0);
    for (; i < length$; ++i) {
      if (i < 0 || i >= e.length)
        throw $.ioore(i);
      t1 = this.call$1(e[i]);
      if (i < 0 || i >= copy.length)
        throw $.ioore(i);
      copy[i] = t1;
    }
    return copy;
  }
  throw $.captureStackTrace($.CTC10);
},
 call$1$bailout: function(state, env0, env1, env2, env3, env4, env5) {
  switch (state) {
    case 1:
      var e = env0;
      break;
    case 2:
      copy = env0;
      elementCopy = env1;
      e = env2;
      length$ = env3;
      i = env4;
      slot = env5;
      break;
    case 3:
      i = env0;
      copy = env1;
      e = env2;
      length$ = env3;
      break;
  }
  switch (state) {
    case 0:
      var t1 = {};
      if (e == null)
        return e;
      if (typeof e === 'boolean')
        return e;
      if (typeof e === 'number')
        return e;
      if (typeof e === 'string')
        return e;
      if (typeof e === 'object' && e !== null && !!e.is$Date)
        throw $.captureStackTrace($.CTC3);
      if (typeof e === 'object' && e !== null && !!e.is$RegExp)
        throw $.captureStackTrace($.CTC4);
      if (typeof e === 'object' && e !== null && e.is$FileImpl())
        return e;
      if (typeof e === 'object' && e !== null && e.is$File())
        throw $.captureStackTrace($.CTC5);
      if (typeof e === 'object' && e !== null && e.is$BlobImpl())
        return e;
      if (typeof e === 'object' && e !== null && e.is$Blob())
        throw $.captureStackTrace($.CTC6);
      if (typeof e === 'object' && e !== null && e.is$FileListImpl())
        return e;
      if (typeof e === 'object' && e !== null && e.is$FileList())
        throw $.captureStackTrace($.CTC7);
      if (typeof e === 'object' && e !== null && e.is$ImageDataImpl())
        return e;
      if (typeof e === 'object' && e !== null && e.is$ImageData())
        throw $.captureStackTrace($.CTC7);
      if (typeof e === 'object' && e !== null && e.is$ArrayBufferImpl())
        return e;
      if (typeof e === 'object' && e !== null && e.is$ArrayBuffer())
        throw $.captureStackTrace($.CTC8);
      if (typeof e === 'object' && e !== null && e.is$ArrayBufferViewImpl())
        return e;
      if (typeof e === 'object' && e !== null && e.is$ArrayBufferView())
        throw $.captureStackTrace($.CTC9);
      if (typeof e === 'object' && e !== null && e.is$Map()) {
        var slot = this.findSlot_8.call$1(e);
        t1.copy_1 = this.readSlot_7.call$1(slot);
        var t2 = t1.copy_1;
        if (!(t2 == null))
          return t2;
        t1.copy_1 = {};
        this.writeSlot_6.call$2(slot, t1.copy_1);
        e.forEach$1(new $._convertDartToNative_PrepareForStructuredClone_walk_anon(this, t1));
        return t1.copy_1;
      }
    default:
      if (state === 3 || state === 2 || state === 1 || state === 0 && typeof e === 'object' && e !== null && (e.constructor === Array || e.is$List()))
        switch (state) {
          case 0:
          case 1:
            state = 0;
            var length$ = $.get$length(e);
            slot = this.findSlot_8.call$1(e);
            var copy = this.readSlot_7.call$1(slot);
            if (!(copy == null)) {
              if (true === copy) {
                copy = new Array(length$);
                this.writeSlot_6.call$2(slot, copy);
              }
              return copy;
            }
          case 2:
            if (state === 2 || state === 0 && e instanceof Array && !!!(e.immutable$list))
              switch (state) {
                case 0:
                  this.writeSlot_6.call$2(slot, true);
                  var i = 0;
                case 2:
                  L0:
                    while (true)
                      switch (state) {
                        case 0:
                          if (!$.ltB(i, length$))
                            break L0;
                          var element = $.index(e, i);
                          var elementCopy = this.call$1(element);
                        case 2:
                          if (state === 2 || state === 0 && !(elementCopy == null ? element == null : elementCopy === element))
                            switch (state) {
                              case 0:
                                copy = this.readSlot_7.call$1(slot);
                                if (true === copy) {
                                  copy = new Array(length$);
                                  this.writeSlot_6.call$2(slot, copy);
                                }
                              case 2:
                                state = 0;
                                for (var j = 0; j < i; ++j)
                                  $.indexSet(copy, j, $.index(e, j));
                                $.indexSet(copy, i, elementCopy);
                                ++i;
                                break L0;
                            }
                          ++i;
                      }
                  if (copy == null) {
                    this.writeSlot_6.call$2(slot, e);
                    copy = e;
                  }
              }
            else {
              copy = new Array(length$);
              this.writeSlot_6.call$2(slot, copy);
              i = 0;
            }
          case 3:
            state = 0;
            for (; $.ltB(i, length$); ++i)
              $.indexSet(copy, i, this.call$1($.index(e, i)));
            return copy;
        }
      throw $.captureStackTrace($.CTC10);
  }
}
};

$$._convertDartToNative_PrepareForStructuredClone_walk_anon = {"":
 ["walk_9", "box_0"],
 super: "Closure",
 call$2: function(key, value) {
  this.box_0.copy_1[key] = this.walk_9.call$1(value);
}
};

$$._convertNativeToDart_AcceptStructuredClone_findSlot = {"":
 ["copies_1", "values_0"],
 super: "Closure",
 call$1: function(value) {
  var length$ = $.get$length(this.values_0);
  if (typeof length$ !== 'number')
    return this.call$1$bailout(1, value, length$);
  for (var i = 0; i < length$; ++i) {
    var t1 = $.index(this.values_0, i);
    if (t1 == null ? value == null : t1 === value)
      return i;
  }
  $.add$1(this.values_0, value);
  $.add$1(this.copies_1, null);
  return length$;
},
 call$1$bailout: function(state, value, length$) {
  for (var i = 0; $.ltB(i, length$); ++i) {
    var t1 = $.index(this.values_0, i);
    if (t1 == null ? value == null : t1 === value)
      return i;
  }
  $.add$1(this.values_0, value);
  $.add$1(this.copies_1, null);
  return length$;
}
};

$$._convertNativeToDart_AcceptStructuredClone_readSlot = {"":
 ["copies_2"],
 super: "Closure",
 call$1: function(i) {
  return $.index(this.copies_2, i);
}
};

$$._convertNativeToDart_AcceptStructuredClone_writeSlot = {"":
 ["copies_3"],
 super: "Closure",
 call$2: function(i, x) {
  $.indexSet(this.copies_3, i, x);
}
};

$$._convertNativeToDart_AcceptStructuredClone_walk = {"":
 ["findSlot_6", "readSlot_5", "writeSlot_4"],
 super: "Closure",
 call$1: function(e) {
  if (typeof e !== 'object' || e === null || (e.constructor !== Array || !!e.immutable$list) && !e.is$JavaScriptIndexingBehavior())
    return this.call$1$bailout(1, e, 0, 0);
  if (e instanceof Date)
    throw $.captureStackTrace($.CTC3);
  if (e instanceof RegExp)
    throw $.captureStackTrace($.CTC4);
  if ($._isJavaScriptSimpleObject(e)) {
    var slot = this.findSlot_6.call$1(e);
    var copy = this.readSlot_5.call$1(slot);
    if (!(copy == null))
      return copy;
    copy = $.makeLiteralMap([]);
    if (typeof copy !== 'object' || copy === null || (copy.constructor !== Array || !!copy.immutable$list) && !copy.is$JavaScriptIndexingBehavior())
      return this.call$1$bailout(2, e, slot, copy);
    this.writeSlot_4.call$2(slot, copy);
    for (var t1 = $.iterator(Object.keys(e)); t1.hasNext$0() === true;) {
      var t2 = t1.next$0();
      var t3 = this.call$1(e[t2]);
      if (t2 !== (t2 | 0))
        throw $.iae(t2);
      if (t2 < 0 || t2 >= copy.length)
        throw $.ioore(t2);
      copy[t2] = t3;
    }
    return copy;
  }
  if (e instanceof Array) {
    slot = this.findSlot_6.call$1(e);
    copy = this.readSlot_5.call$1(slot);
    if (!(copy == null))
      return copy;
    this.writeSlot_4.call$2(slot, e);
    var length$ = e.length;
    for (var i = 0; i < length$; ++i) {
      if (i < 0 || i >= e.length)
        throw $.ioore(i);
      t1 = this.call$1(e[i]);
      if (i < 0 || i >= e.length)
        throw $.ioore(i);
      e[i] = t1;
    }
    return e;
  }
  return e;
},
 call$1$bailout: function(state, env0, env1, env2) {
  switch (state) {
    case 1:
      var e = env0;
      break;
    case 2:
      e = env0;
      slot = env1;
      copy = env2;
      break;
  }
  switch (state) {
    case 0:
    case 1:
      state = 0;
      if (e == null)
        return e;
      if (typeof e === 'boolean')
        return e;
      if (typeof e === 'number')
        return e;
      if (typeof e === 'string')
        return e;
      if (e instanceof Date)
        throw $.captureStackTrace($.CTC3);
      if (e instanceof RegExp)
        throw $.captureStackTrace($.CTC4);
    case 2:
      if (state === 2 || state === 0 && $._isJavaScriptSimpleObject(e))
        switch (state) {
          case 0:
            var slot = this.findSlot_6.call$1(e);
            var copy = this.readSlot_5.call$1(slot);
            if (!(copy == null))
              return copy;
            copy = $.makeLiteralMap([]);
          case 2:
            state = 0;
            this.writeSlot_4.call$2(slot, copy);
            for (var t1 = $.iterator(Object.keys(e)); t1.hasNext$0() === true;) {
              var t2 = t1.next$0();
              $.indexSet(copy, t2, this.call$1(e[t2]));
            }
            return copy;
        }
      if (e instanceof Array) {
        slot = this.findSlot_6.call$1(e);
        copy = this.readSlot_5.call$1(slot);
        if (!(copy == null))
          return copy;
        this.writeSlot_4.call$2(slot, e);
        var length$ = $.get$length(e);
        for (var i = 0; $.ltB(i, length$); ++i)
          $.indexSet(e, i, this.call$1($.index(e, i)));
        return e;
      }
      return e;
  }
}
};

$$.Maps__emitMap_anon = {"":
 ["result_3", "box_0", "visiting_2"],
 super: "Closure",
 call$2: function(k, v) {
  if (this.box_0.first_1 !== true)
    $.add$1(this.result_3, ', ');
  this.box_0.first_1 = false;
  $.Collections__emitObject(k, this.result_3, this.visiting_2);
  $.add$1(this.result_3, ': ');
  $.Collections__emitObject(v, this.result_3, this.visiting_2);
}
};

$$.LinkedHashMapImplementation_forEach__ = {"":
 ["f_0"],
 super: "Closure",
 call$1: function(entry) {
  this.f_0.call$2(entry.get$key(), entry.get$value());
}
};

$$._convertNativeToDart_IDBKey_containsDate = {"":
 [],
 super: "Closure",
 call$1: function(object) {
  if (object instanceof Date)
    return true;
  if (typeof object === 'object' && object !== null && (object.constructor === Array || object.is$List())) {
    if (typeof object !== 'object' || object === null || object.constructor !== Array && !object.is$JavaScriptIndexingBehavior())
      return this.call$1$bailout(1, object);
    for (var i = 0; t1 = object.length, i < t1; ++i) {
      if (i < 0 || i >= t1)
        throw $.ioore(i);
      if (this.call$1(object[i]) === true)
        return true;
    }
  }
  return false;
  var t1;
},
 call$1$bailout: function(state, env0) {
  switch (state) {
    case 1:
      var object = env0;
      break;
  }
  switch (state) {
    case 0:
      if (object instanceof Date)
        return true;
    case 1:
      if (state === 1 || state === 0 && typeof object === 'object' && object !== null && (object.constructor === Array || object.is$List()))
        switch (state) {
          case 0:
          case 1:
            state = 0;
            for (var i = 0; $.ltB(i, $.get$length(object)); ++i)
              if (this.call$1($.index(object, i)) === true)
                return true;
        }
      return false;
  }
}
};

$$.DoubleLinkedQueue_length__ = {"":
 ["box_0"],
 super: "Closure",
 call$1: function(element) {
  var counter = $.add(this.box_0.counter_1, 1);
  this.box_0.counter_1 = counter;
}
};

$$.FancyDivElement_FancyDivElement$component_anon = {"":
 [],
 super: "Closure",
 call$0: function() {
  return $.FancyDivElement$_internal();
}
};

$$.CustomElementsManager__loadComponents_anon = {"":
 ["this_0"],
 super: "Closure",
 call$1: function(link) {
  return this.this_0._load$1(link.get$href());
}
};

$$.CustomElementsManager__expandDeclarations_anon = {"":
 [],
 super: "Closure",
 call$1: function(e) {
  return e.matchesSelector$1('template *') !== true;
}
};

$$.FancyDivElement_inserted_anon = {"":
 ["this_0"],
 super: "Closure",
 call$1: function(e) {
  var t1 = '<p>' + $.S(this.this_0.generateIdiom$0()) + '</p>';
  this.this_0.get$_root().set$innerHTML(t1);
  return t1;
}
};

$$.FilteredElementList__filtered_anon = {"":
 [],
 super: "Closure",
 call$1: function(n) {
  return typeof n === 'object' && n !== null && n.is$Element();
}
};

$$._ChildrenElementList_filter_anon = {"":
 ["f_1", "output_0"],
 super: "Closure",
 call$1: function(element) {
  if (this.f_1.call$1(element) === true)
    $.add$1(this.output_0, element);
}
};

$$.FilteredElementList_removeRange_anon = {"":
 [],
 super: "Closure",
 call$1: function(el) {
  return el.remove$0();
}
};

$$.invokeClosure_anon = {"":
 ["closure_0"],
 super: "Closure",
 call$0: function() {
  return this.closure_0.call$0();
}
};

$$.invokeClosure_anon0 = {"":
 ["closure_2", "arg1_1"],
 super: "Closure",
 call$0: function() {
  return this.closure_2.call$1(this.arg1_1);
}
};

$$.invokeClosure_anon1 = {"":
 ["closure_5", "arg1_4", "arg2_3"],
 super: "Closure",
 call$0: function() {
  return this.closure_5.call$2(this.arg1_4, this.arg2_3);
}
};

$$.HashSetImplementation_addAll__ = {"":
 ["this_0"],
 super: "Closure",
 call$1: function(value) {
  this.this_0.add$1(value);
}
};

$$.HashSetImplementation_forEach__ = {"":
 ["f_0"],
 super: "Closure",
 call$2: function(key, value) {
  this.f_0.call$1(key);
}
};

$$.HashSetImplementation_filter__ = {"":
 ["result_1", "f_0"],
 super: "Closure",
 call$2: function(key, value) {
  if (this.f_0.call$1(key) === true)
    $.add$1(this.result_1, key);
}
};

$$._CssClassSet_add_anon = {"":
 ["value_0"],
 super: "Closure",
 call$1: function(s) {
  return $.add$1(s, this.value_0);
}
};

$$._CssClassSet_addAll_anon = {"":
 ["collection_0"],
 super: "Closure",
 call$1: function(s) {
  return $.addAll(s, this.collection_0);
}
};

$$._CssClassSet_clear_anon = {"":
 [],
 super: "Closure",
 call$1: function(s) {
  return $.clear(s);
}
};

$$.ConstantMap_forEach_anon = {"":
 ["this_1", "f_0"],
 super: "Closure",
 call$1: function(key) {
  return this.f_0.call$2(key, $.index(this.this_1, key));
}
};

$$.ConstantMap_getValues_anon = {"":
 ["this_1", "result_0"],
 super: "Closure",
 call$1: function(key) {
  return $.add$1(this.result_0, $.index(this.this_1, key));
}
};

$$.StorageImpl_getValues_anon = {"":
 ["values_0"],
 super: "Closure",
 call$2: function(k, v) {
  return $.add$1(this.values_0, v);
}
};

$$.LinkedHashMapImplementation_getValues__ = {"":
 ["list_2", "box_0"],
 super: "Closure",
 call$1: function(entry) {
  var t1 = this.list_2;
  var t2 = this.box_0.index_1;
  var index = $.add(t2, 1);
  this.box_0.index_1 = index;
  $.indexSet(t1, t2, entry.get$value());
}
};

$$.HashMapImplementation_getValues__ = {"":
 ["list_2", "box_0"],
 super: "Closure",
 call$2: function(key, value) {
  var t1 = this.list_2;
  var t2 = this.box_0.i_1;
  var i = $.add(t2, 1);
  this.box_0.i_1 = i;
  $.indexSet(t1, t2, value);
}
};

$$.CustomElementsManager__load_anon = {"":
 ["this_1", "request_0"],
 super: "Closure",
 call$1: function(e) {
  if ($.eqB(this.request_0.get$readyState(), 4))
    if ($.geB(this.request_0.get$status(), 200) && $.ltB(this.request_0.get$status(), 300) || $.eqB(this.request_0.get$status(), 304) || $.eqB(this.request_0.get$status(), 0))
      $.forEach(this.this_1._parse$1(this.request_0.get$response()), new $.CustomElementsManager__load_anon0(this.this_1));
    else
      $.window().get$console().error$1('Unable to load component: Status ' + $.S(this.request_0.get$status()) + ' - ' + $.S(this.request_0.get$statusText()));
}
};

$$.CustomElementsManager__load_anon0 = {"":
 ["this_2"],
 super: "Closure",
 call$1: function(declaration) {
  $.indexSet(this.this_2.get$_customDeclarations(), declaration.get$name(), declaration);
}
};

$$.CustomElementsManager__parse_anon = {"":
 ["newDeclarations_0"],
 super: "Closure",
 call$1: function(element) {
  $.add$1(this.newDeclarations_0, $._CustomDeclaration$(element));
}
};

$$._CustomDeclaration_morph_anon = {"":
 ["box_0"],
 super: "Closure",
 call$1: function(node) {
  return $.add$1(this.box_0.shadowRoot_1.get$nodes(), node.clone$1(true));
}
};

$$._CustomDeclaration_morph_anon0 = {"":
 ["box_0"],
 super: "Closure",
 call$2: function(mutations, observer) {
  for (var t1 = $.iterator(mutations); t1.hasNext$0() === true;) {
    var t2 = t1.next$0();
    if ($.eqB(t2.get$type(), 'attributes')) {
      var attrName = t2.get$attributeName();
      var element = t2.get$target();
      this.box_0.newCustomElement_2.attributeChanged$3(attrName, t2.get$oldValue(), $.index(element.get$attributes(), attrName));
    }
  }
}
};

$$.CustomElementsManager_initializeInsertedRemovedCallbacks_anon = {"":
 ["this_0"],
 super: "Closure",
 call$2: function(mutations, observer) {
  for (var t1 = $.iterator(mutations); t1.hasNext$0() === true;) {
    var t2 = t1.next$0();
    if ($.eqB(t2.get$type(), 'childList')) {
      for (var t3 = $.iterator(t2.get$addedNodes()); t3.hasNext$0() === true;) {
        var t4 = t3.next$0();
        if (typeof t4 === 'object' && t4 !== null && t4.is$Element())
          this.this_0._expandDeclarations$1(t4);
      }
      for (t3 = $.iterator(t2.get$removedNodes()); t3.hasNext$0() === true;) {
        t2 = t3.next$0();
        if (typeof t2 === 'object' && t2 !== null && t2.is$Element())
          this.this_0._removeComponents$1(t2);
      }
    }
  }
}
};

$$.MutationObserverImpl_observe_anon = {"":
 ["parsedOptions_0"],
 super: "Closure",
 call$2: function(k, v) {
  if ($.CTC28.containsKey$1(k) === true)
    this.parsedOptions_0[k] = true === v;
  else if ($.eqB(k, 'attributeFilter'))
    this.parsedOptions_0[k] = v;
  else
    throw $.captureStackTrace($.IllegalArgumentException$('Illegal MutationObserver.observe option \'' + $.S(k) + '\''));
}
};

$$.MutationObserverImpl_observe_override = {"":
 ["parsedOptions_1"],
 super: "Closure",
 call$2: function(key, value) {
  if (!(value == null))
    this.parsedOptions_1[key] = value;
}
};

$$.BoundClosure = {'':
 ['self', 'target'],
 'super': 'Closure',
call$0: function() { return this.self[this.target](); }
};
$$.BoundClosure0 = {'':
 ['self', 'target'],
 'super': 'Closure',
call$1: function(p0) { return this.self[this.target](p0); }
};
$.mul$slow = function(a, b) {
  if ($.checkNumbers(a, b))
    return a * b;
  return a.operator$mul$1(b);
};

$._componentsMetadata0 = function(m) {
  $componentsMetadata = m;
};

$.hasShadowRoot = function() {
  if ($._hasShadowRoot == null)
    try {
      $._ShadowRootFactoryProvider_ShadowRoot($._Elements_DivElement());
      $._hasShadowRoot = true;
    } catch (exception) {
      $.unwrapException(exception);
      $._hasShadowRoot = false;
      var style = $._ElementFactoryProvider_Element$html('<style type="text/css">template { display: none; }</style>');
      $.add$1($.document().get$head().get$nodes(), style);
    }

  return $._hasShadowRoot;
};

$._ChildNodeListLazy$ = function(_this) {
  return new $._ChildNodeListLazy(_this);
};

$.floor = function(receiver) {
  return Math.floor(receiver);
};

$.eqB = function(a, b) {
  if (a == null)
    return b == null;
  if (b == null)
    return false;
  if (typeof a === "object")
    if (!!a.operator$eq$1)
      return a.operator$eq$1(b) === true;
  return a === b;
};

$._convertNativeToDart_AcceptStructuredClone = function(object) {
  var values = [];
  var copies = [];
  return new $._convertNativeToDart_AcceptStructuredClone_walk(new $._convertNativeToDart_AcceptStructuredClone_findSlot(copies, values), new $._convertNativeToDart_AcceptStructuredClone_readSlot(copies), new $._convertNativeToDart_AcceptStructuredClone_writeSlot(copies)).call$1(object);
};

$.Collections__containsRef = function(c, ref) {
  for (var t1 = $.iterator(c); t1.hasNext$0() === true;) {
    var t2 = t1.next$0();
    if (t2 == null ? ref == null : t2 === ref)
      return true;
  }
  return false;
};

$._NodeListWrapper$ = function(list) {
  return new $._NodeListWrapper(list);
};

$._isJavaScriptSimpleObject = function(value) {
  return Object.getPrototypeOf(value) === Object.prototype;
};

$.jsHasOwnProperty = function(jsObject, property) {
  return jsObject.hasOwnProperty(property);
};

$._Collections_forEach = function(iterable, f) {
  for (var t1 = $.iterator(iterable); t1.hasNext$0() === true;)
    f.call$1(t1.next$0());
};

$.isJsArray = function(value) {
  return !(value == null) && value.constructor === Array;
};

$.indexSet$slow = function(a, index, value) {
  if ($.isJsArray(a)) {
    if (!(typeof index === 'number' && index === (index | 0)))
      throw $.captureStackTrace($.IllegalArgumentException$(index));
    if (index < 0 || $.geB(index, $.get$length(a)))
      throw $.captureStackTrace($.IndexOutOfRangeException$(index));
    $.checkMutable(a, 'indexed set');
    a[index] = value;
    return;
  }
  a.operator$indexSet$2(index, value);
};

$.HashMapImplementation__nextProbe = function(currentProbe, numberOfProbes, length$) {
  return $.and($.add(currentProbe, numberOfProbes), $.sub(length$, 1));
};

$.IDBOpenDBRequestEventsImpl$ = function(_ptr) {
  return new $.IDBOpenDBRequestEventsImpl(_ptr);
};

$.AudioContextEventsImpl$ = function(_ptr) {
  return new $.AudioContextEventsImpl(_ptr);
};

$.substringUnchecked = function(receiver, startIndex, endIndex) {
  return receiver.substring(startIndex, endIndex);
};

$.get$length = function(receiver) {
  if (typeof receiver === 'string' || $.isJsArray(receiver))
    return receiver.length;
  else
    return receiver.get$length();
};

$.ge$slow = function(a, b) {
  if ($.checkNumbers(a, b))
    return a >= b;
  return a.operator$ge$1(b);
};

$.FancyDivElement$_internal = function() {
  return new $.FancyDivElement(null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);
};

$.DocumentEventsImpl$ = function(_ptr) {
  return new $.DocumentEventsImpl(_ptr);
};

$.IllegalJSRegExpException$ = function(_pattern, _errmsg) {
  return new $.IllegalJSRegExpException(_pattern, _errmsg);
};

$.MediaStreamTrackListEventsImpl$ = function(_ptr) {
  return new $.MediaStreamTrackListEventsImpl(_ptr);
};

$.queryAll = function(selector) {
  return $._document().queryAll$1(selector);
};

$.clear = function(receiver) {
  if (!$.isJsArray(receiver))
    return receiver.clear$0();
  $.set$length(receiver, 0);
};

$.IDBDatabaseEventsImpl$ = function(_ptr) {
  return new $.IDBDatabaseEventsImpl(_ptr);
};

$.typeNameInIE = function(obj) {
  var name$ = $.constructorNameFallback(obj);
  if (name$ === 'Window')
    return 'DOMWindow';
  if (name$ === 'Document') {
    if (!!obj.xmlVersion)
      return 'Document';
    return 'HTMLDocument';
  }
  if (name$ === 'CanvasPixelArray')
    return 'Uint8ClampedArray';
  if (name$ === 'DataTransfer')
    return 'Clipboard';
  if (name$ === 'DragEvent')
    return 'MouseEvent';
  if (name$ === 'HTMLDDElement')
    return 'HTMLElement';
  if (name$ === 'HTMLDTElement')
    return 'HTMLElement';
  if (name$ === 'HTMLTableDataCellElement')
    return 'HTMLTableCellElement';
  if (name$ === 'HTMLTableHeaderCellElement')
    return 'HTMLTableCellElement';
  if (name$ === 'HTMLPhraseElement')
    return 'HTMLElement';
  if (name$ === 'MSStyleCSSProperties')
    return 'CSSStyleDeclaration';
  if (name$ === 'MouseWheelEvent')
    return 'WheelEvent';
  return name$;
};

$.constructorNameFallback = function(obj) {
  var constructor$ = obj.constructor;
  if (typeof(constructor$) === 'function') {
    var name$ = constructor$.name;
    if (typeof name$ === 'string')
      var t1 = !(name$ === '') && !(name$ === 'Object') && !(name$ === 'Function.prototype');
    else
      t1 = false;
    if (t1)
      return name$;
  }
  var string = Object.prototype.toString.call(obj);
  return string.substring(8, string.length - 1);
};

$.rewirePrototypeChain = function(nativeElement, closure, name$) {
  var componentPrototype = $._componentsMetadata()[name$];
  if (componentPrototype == null) {
    var nonNativeElement = closure.call$0();
    componentPrototype = Object.getPrototypeOf(nonNativeElement);
    $._componentsMetadata()[name$] = componentPrototype;
    if ($._supportsProto() === true && Object.isPrototypeOf.call(Object.getPrototypeOf(nativeElement), nonNativeElement) !== true) {
      for (var currProto = componentPrototype; Object.getPrototypeOf(currProto) === Object.prototype !== true;)
        currProto = Object.getPrototypeOf(currProto);
      currProto.__proto__ = Object.getPrototypeOf(nativeElement);
    }
  }
  if ($._supportsProto() === true)
    nativeElement.__proto__ = componentPrototype;
  else
    $._copyProperties(componentPrototype, nativeElement, false);
};

$.NullPointerException$ = function(functionName, arguments$) {
  return new $.NullPointerException(functionName, arguments$);
};

$.AbstractWorkerEventsImpl$ = function(_ptr) {
  return new $.AbstractWorkerEventsImpl(_ptr);
};

$.DoubleLinkedQueueEntry$ = function(e, E) {
  var t1 = new $.DoubleLinkedQueueEntry(null, null, null);
  $.setRuntimeTypeInfo(t1, { 'E': E });
  t1.DoubleLinkedQueueEntry$1(e);
  return t1;
};

$.regExpMatchStart = function(m) {
  return m.index;
};

$.tdiv = function(a, b) {
  if ($.checkNumbers(a, b))
    return $.truncate(a / b);
  return a.operator$tdiv$1(b);
};

$.Primitives_printString = function(string) {
  if (typeof dartPrint == "function") {
    dartPrint(string);
    return;
  }
  if (typeof console == "object") {
    console.log(string);
    return;
  }
  if (typeof write == "function") {
    write(string);
    write("\n");
  }
};

$.typeNameInChrome = function(obj) {
  var name$ = obj.constructor.name;
  if (name$ === 'Window')
    return 'DOMWindow';
  if (name$ === 'CanvasPixelArray')
    return 'Uint8ClampedArray';
  if (name$ === 'WebKitMutationObserver')
    return 'MutationObserver';
  return name$;
};

$.MediaStreamEventsImpl$ = function(_ptr) {
  return new $.MediaStreamEventsImpl(_ptr);
};

$.IDBRequestEventsImpl$ = function(_ptr) {
  return new $.IDBRequestEventsImpl(_ptr);
};

$.WindowEventsImpl$ = function(_ptr) {
  return new $.WindowEventsImpl(_ptr);
};

$.manager = function() {
  return $._manager;
};

$.shr = function(a, b) {
  if ($.checkNumbers(a, b)) {
    if (b < 0)
      throw $.captureStackTrace($.IllegalArgumentException$(b));
    if (a > 0) {
      if (b > 31)
        return 0;
      return a >>> b;
    }
    if (b > 31)
      b = 31;
    return (a >> b) >>> 0;
  }
  return a.operator$shr$1(b);
};

$.ObjectImplementation_toStringImpl = function(object) {
  return $.Primitives_objectToString(object);
};

$._Pair$ = function(_key, _value, K, V) {
  var t1 = new $._Pair(_key, _value);
  $.setRuntimeTypeInfo(t1, { 'K': K, 'V': V });
  return t1;
};

$.and = function(a, b) {
  if ($.checkNumbers(a, b))
    return (a & b) >>> 0;
  return a.operator$and$1(b);
};

$.substring$2 = function(receiver, startIndex, endIndex) {
  $.checkNum(startIndex);
  var length$ = receiver.length;
  if (endIndex == null)
    endIndex = length$;
  $.checkNum(endIndex);
  if (startIndex < 0)
    throw $.captureStackTrace($.IndexOutOfRangeException$(startIndex));
  if ($.gtB(startIndex, endIndex))
    throw $.captureStackTrace($.IndexOutOfRangeException$(startIndex));
  if ($.gtB(endIndex, length$))
    throw $.captureStackTrace($.IndexOutOfRangeException$(endIndex));
  return $.substringUnchecked(receiver, startIndex, endIndex);
};

$.indexSet = function(a, index, value) {
  if (a.constructor === Array && !a.immutable$list) {
    var key = index >>> 0;
    if (key === index && key < a.length) {
      a[key] = value;
      return;
    }
  }
  $.indexSet$slow(a, index, value);
};

$.ExceptionImplementation$ = function(msg) {
  return new $.ExceptionImplementation(msg);
};

$.invokeClosure = function(closure, isolate, numberOfArguments, arg1, arg2) {
  if ($.eqB(numberOfArguments, 0))
    return new $.invokeClosure_anon(closure).call$0();
  else if ($.eqB(numberOfArguments, 1))
    return new $.invokeClosure_anon0(closure, arg1).call$0();
  else if ($.eqB(numberOfArguments, 2))
    return new $.invokeClosure_anon1(closure, arg1, arg2).call$0();
  else
    throw $.captureStackTrace($.ExceptionImplementation$('Unsupported number of arguments for wrapped closure'));
};

$.last = function(receiver) {
  if (!$.isJsArray(receiver))
    return receiver.last$0();
  return $.index(receiver, $.sub($.get$length(receiver), 1));
};

$.stringJoinUnchecked = function(array, separator) {
  return array.join(separator);
};

$.gt = function(a, b) {
  return typeof a === 'number' && typeof b === 'number' ? a > b : $.gt$slow(a, b);
};

$.filter = function(receiver, predicate) {
  if (!$.isJsArray(receiver))
    return receiver.filter$1(predicate);
  else
    return $.Collections_filter(receiver, [], predicate);
};

$.WorkerEventsImpl$ = function(_ptr) {
  return new $.WorkerEventsImpl(_ptr);
};

$.buildDynamicMetadata = function(inputTable) {
  var result = [];
  for (var i = 0; i < inputTable.length; ++i) {
    var tag = inputTable[i][0];
    var array = inputTable[i];
    var tags = array[1];
    var set = {};
    var tagNames = tags.split('|');
    for (var j = 0, index = 1; j < tagNames.length; ++j) {
      $.propertySet(set, tagNames[j], true);
      index = j;
      array = tagNames;
    }
    result.push($.MetaInfo$(tag, tags, set));
  }
  return result;
};

$.propertySet = function(object, property, value) {
  object[property] = value;
};

$.Collections_filter = function(source, destination, f) {
  for (var t1 = $.iterator(source); t1.hasNext$0() === true;) {
    var t2 = t1.next$0();
    if (f.call$1(t2) === true)
      destination.push(t2);
  }
  return destination;
};

$.contains$1 = function(receiver, other) {
  return $.contains$2(receiver, other, 0);
};

$._Collections_filter = function(source, destination, f) {
  for (var t1 = $.iterator(source); t1.hasNext$0() === true;) {
    var t2 = t1.next$0();
    if (f.call$1(t2) === true)
      destination.push(t2);
  }
  return destination;
};

$.mul = function(a, b) {
  return typeof a === 'number' && typeof b === 'number' ? a * b : $.mul$slow(a, b);
};

$._browserPrefix = function() {
  if ($._cachedBrowserPrefix == null)
    if ($._Device_isFirefox() === true)
      $._cachedBrowserPrefix = '-moz-';
    else
      $._cachedBrowserPrefix = '-webkit-';
  return $._cachedBrowserPrefix;
};

$.Collections__emitCollection = function(c, result, visiting) {
  $.add$1(visiting, c);
  var isList = typeof c === 'object' && c !== null && (c.constructor === Array || c.is$List());
  $.add$1(result, isList ? '[' : '{');
  for (var t1 = $.iterator(c), first = true; t1.hasNext$0() === true;) {
    var t2 = t1.next$0();
    if (!first)
      $.add$1(result, ', ');
    $.Collections__emitObject(t2, result, visiting);
    first = false;
  }
  $.add$1(result, isList ? ']' : '}');
  $.removeLast(visiting);
};

$._convertNativeToDart_IDBKey = function(nativeKey) {
  if (new $._convertNativeToDart_IDBKey_containsDate().call$1(nativeKey) === true)
    throw $.captureStackTrace($.CTC13);
  return nativeKey;
};

$.checkMutable = function(list, reason) {
  if (!!(list.immutable$list))
    throw $.captureStackTrace($.UnsupportedOperationException$(reason));
};

$.HttpRequestEventsImpl$ = function(_ptr) {
  return new $.HttpRequestEventsImpl(_ptr);
};

$.sub$slow = function(a, b) {
  if ($.checkNumbers(a, b))
    return a - b;
  return a.operator$sub$1(b);
};

$.toStringWrapper = function() {
  return $.toString(this.dartException);
};

$._ElementList$ = function(list) {
  return new $._ElementList(list);
};

$.IDBVersionChangeRequestEventsImpl$ = function(_ptr) {
  return new $.IDBVersionChangeRequestEventsImpl(_ptr);
};

$.ElementEventsImpl$ = function(_ptr) {
  return new $.ElementEventsImpl(_ptr);
};

$.regExpTest = function(regExp, str) {
  return $.regExpGetNative(regExp).test(str);
};

$.typeNameInOpera = function(obj) {
  var name$ = $.constructorNameFallback(obj);
  if (name$ === 'Window')
    return 'DOMWindow';
  return name$;
};

$.DedicatedWorkerContextEventsImpl$ = function(_ptr) {
  return new $.DedicatedWorkerContextEventsImpl(_ptr);
};

$.HashSetImplementation$ = function(E) {
  var t1 = new $.HashSetImplementation(null);
  $.setRuntimeTypeInfo(t1, { 'E': E });
  t1.HashSetImplementation$0();
  return t1;
};

$.stringSplitUnchecked = function(receiver, pattern) {
  return receiver.split(pattern);
};

$.isEmpty = function(receiver) {
  if (typeof receiver === 'string' || $.isJsArray(receiver))
    return receiver.length === 0;
  return receiver.isEmpty$0();
};

$.checkGrowable = function(list, reason) {
  if (!!(list.fixed$length))
    throw $.captureStackTrace($.UnsupportedOperationException$(reason));
};

$.ListMap$ = function(K, V) {
  var t1 = new $.ListMap($.ListImplementation_List(null, '_Pair<K, V>'));
  $.setRuntimeTypeInfo(t1, { 'K': K, 'V': V });
  return t1;
};

$.FrameSetElementEventsImpl$ = function(_ptr) {
  return new $.FrameSetElementEventsImpl(_ptr);
};

$.add$1 = function(receiver, value) {
  if ($.isJsArray(receiver)) {
    $.checkGrowable(receiver, 'add');
    receiver.push(value);
    return;
  }
  return receiver.add$1(value);
};

$.regExpExec = function(regExp, str) {
  var result = $.regExpGetNative(regExp).exec(str);
  if (result === null)
    return;
  return result;
};

$.contains = function(userAgent, name$) {
  return !(userAgent.indexOf(name$) === -1);
};

$.geB = function(a, b) {
  return typeof a === 'number' && typeof b === 'number' ? a >= b : $.ge$slow(a, b) === true;
};

$.stringContainsUnchecked = function(receiver, other, startIndex) {
  return !($.indexOf$2(receiver, other, startIndex) === -1);
};

$.ObjectNotClosureException$ = function() {
  return new $.ObjectNotClosureException();
};

$.window = function() {
return window;
};

$.add = function(a, b) {
  return typeof a === 'number' && typeof b === 'number' ? a + b : $.add$slow(a, b);
};

$._DocumentFragmentFactoryProvider_DocumentFragment = function() {
  return $.document().createDocumentFragment$0();
};

$._MatchImplementation$ = function(pattern, str, _start, _end, _groups) {
  return new $._MatchImplementation(pattern, str, _start, _end, _groups);
};

$.typeNameInSafari = function(obj) {
  var name$ = $.constructorNameFallback(obj);
  if (name$ === 'Window')
    return 'DOMWindow';
  if (name$ === 'CanvasPixelArray')
    return 'Uint8ClampedArray';
  if (name$ === 'WebKitMutationObserver')
    return 'MutationObserver';
  return name$;
};

$.Primitives_objectTypeName = function(object) {
  var name$ = $.constructorNameFallback(object);
  if ($.eqB(name$, 'Object')) {
    var decompiled = String(object.constructor).match(/^\s*function\s*(\S*)\s*\(/)[1];
    if (typeof decompiled === 'string')
      name$ = decompiled;
  }
  return $.charCodeAt(name$, 0) === 36 ? $.substring$1(name$, 1) : name$;
};

$.EventSourceEventsImpl$ = function(_ptr) {
  return new $.EventSourceEventsImpl(_ptr);
};

$.regExpMakeNative = function(regExp, global) {
  var pattern = regExp.get$pattern();
  var multiLine = regExp.get$multiLine();
  var ignoreCase = regExp.get$ignoreCase();
  $.checkString(pattern);
  var sb = $.StringBufferImpl$('');
  if (multiLine === true)
    $.add$1(sb, 'm');
  if (ignoreCase === true)
    $.add$1(sb, 'i');
  if (global)
    $.add$1(sb, 'g');
  try {
    return new RegExp(pattern, $.toString(sb));
  } catch (exception) {
    var t1 = $.unwrapException(exception);
    var e = t1;
    throw $.captureStackTrace($.IllegalJSRegExpException$(pattern, String(e)));
  }

};

$.iterator = function(receiver) {
  if ($.isJsArray(receiver))
    return $.ListIterator$(receiver);
  return receiver.iterator$0();
};

$._FrozenElementListIterator$ = function(_list) {
  return new $._FrozenElementListIterator(_list, 0);
};

$.EventListenerListImpl$ = function(_ptr, _type) {
  return new $.EventListenerListImpl(_ptr, _type);
};

$.Maps_mapToString = function(m) {
  var result = $.StringBufferImpl$('');
  $.Maps__emitMap(m, result, $.ListImplementation_List(null));
  return result.toString$0();
};

$.BatteryManagerEventsImpl$ = function(_ptr) {
  return new $.BatteryManagerEventsImpl(_ptr);
};

$._MutationObserverFactoryProvider_MutationObserver = function(callback) {
  callback = $.convertDartClosureToJS(callback, 2);
    var constructor =
        window.MutationObserver || window.WebKitMutationObserver ||
        window.MozMutationObserver;
    return new constructor(callback);
  
};

$.SpeechRecognitionEventsImpl$ = function(_ptr) {
  return new $.SpeechRecognitionEventsImpl(_ptr);
};

$.Collections__emitObject = function(o, result, visiting) {
  if (typeof o === 'object' && o !== null && (o.constructor === Array || o.is$Collection()))
    if ($.Collections__containsRef(visiting, o))
      $.add$1(result, typeof o === 'object' && o !== null && (o.constructor === Array || o.is$List()) ? '[...]' : '{...}');
    else
      $.Collections__emitCollection(o, result, visiting);
  else if (typeof o === 'object' && o !== null && o.is$Map())
    if ($.Collections__containsRef(visiting, o))
      $.add$1(result, '{...}');
    else
      $.Maps__emitMap(o, result, visiting);
  else
    $.add$1(result, o == null ? 'null' : o);
};

$._ProtoTester$ = function() {
  return new $._ProtoTester(null);
};

$.Maps__emitMap = function(m, result, visiting) {
  var t1 = {};
  $.add$1(visiting, m);
  $.add$1(result, '{');
  t1.first_1 = true;
  $.forEach(m, new $.Maps__emitMap_anon(result, t1, visiting));
  $.add$1(result, '}');
  $.removeLast(visiting);
};

$._Device_isFirefox = function() {
  return $.contains$2($._Device_userAgent(), 'Firefox', 0);
};

$.WebSocketEventsImpl$ = function(_ptr) {
  return new $.WebSocketEventsImpl(_ptr);
};

$.UnsupportedOperationException$ = function(_message) {
  return new $.UnsupportedOperationException(_message);
};

$.indexOf$2 = function(receiver, element, start) {
  if ($.isJsArray(receiver))
    return $.Arrays_indexOf(receiver, element, start, receiver.length);
  else {
    $.checkNull(element);
    if (start < 0)
      return -1;
    return receiver.indexOf(element, start);
  }
  return receiver.indexOf$2(element, start);
};

$.MediaStreamTrackEventsImpl$ = function(_ptr) {
  return new $.MediaStreamTrackEventsImpl(_ptr);
};

$.NoMoreElementsException$ = function() {
  return new $.NoMoreElementsException();
};

$.FancyDivElement_FancyDivElement$component = function() {
  if ($.FancyDivElement__$constr == null)
    $.FancyDivElement__$constr = new $.FancyDivElement_FancyDivElement$component_anon();
  var t1 = $._Elements_DivElement();
  $.rewirePrototypeChain(t1, $.FancyDivElement__$constr, 'NotAWrapper');
  return t1;
};

$._ElementFactoryProvider_Element$tag = function(tag) {
return document.createElement(tag)
};

$.add$slow = function(a, b) {
  if ($.checkNumbers(a, b))
    return a + b;
  return a.operator$add$1(b);
};

$.ListImplementation_List$from = function(other, E) {
  var result = $.ListImplementation_List(null);
  for (var t1 = $.iterator(other); t1.hasNext$0() === true;)
    result.push(t1.next$0());
  return result;
};

$.getRuntimeTypeInfo = function(target) {
  if (target == null)
    return;
  var res = target.builtin$typeInfo;
  return res == null ? {} : res;
};

$.Primitives_newList = function(length$) {
  if (length$ == null)
    return new Array();
  if (!(typeof length$ === 'number' && length$ === (length$ | 0)) || length$ < 0)
    throw $.captureStackTrace($.IllegalArgumentException$(length$));
  var result = new Array(length$);
  result.fixed$length = true;
  return result;
};

$.main = function() {
  $._componentsSetup();
};

$.HashSetIterator$ = function(set_, E) {
  var t1 = new $.HashSetIterator(set_.get$_backingMap().get$_keys(), -1);
  $.setRuntimeTypeInfo(t1, { 'E': E });
  t1.HashSetIterator$1(set_);
  return t1;
};

$._convertDartToNative_SerializedScriptValue = function(value) {
  return $._convertDartToNative_PrepareForStructuredClone(value);
};

$.IllegalArgumentException$ = function(arg) {
  return new $.IllegalArgumentException(arg);
};

$.iae = function(argument) {
  throw $.captureStackTrace($.IllegalArgumentException$(argument));
};

$.truncate = function(receiver) {
  return receiver < 0 ? $.ceil(receiver) : $.floor(receiver);
};

$.PeerConnection00EventsImpl$ = function(_ptr) {
  return new $.PeerConnection00EventsImpl(_ptr);
};

$._ChildrenElementList$_wrap = function(element) {
  return new $._ChildrenElementList(element, element.get$$$dom_children());
};

$.dynamicSetMetadata = function(inputTable) {
  var t1 = $.buildDynamicMetadata(inputTable);
  $._dynamicMetadata(t1);
};

$._convertDartToNative_PrepareForStructuredClone = function(value) {
  var values = [];
  var copies = [];
  var t1 = new $._convertDartToNative_PrepareForStructuredClone_findSlot(copies, values);
  var t2 = new $._convertDartToNative_PrepareForStructuredClone_readSlot(copies);
  var t3 = new $._convertDartToNative_PrepareForStructuredClone_writeSlot(copies);
  var t4 = new $._convertDartToNative_PrepareForStructuredClone_cleanupSlots();
  var copy = new $._convertDartToNative_PrepareForStructuredClone_walk(t1, t2, t3).call$1(value);
  t4.call$0();
  return copy;
};

$._ShadowRootFactoryProvider_ShadowRoot = function(host) {
      return new WebKitShadowRoot(host);
    
};

$.MediaElementEventsImpl$ = function(_ptr) {
  return new $.MediaElementEventsImpl(_ptr);
};

$.endsWith = function(receiver, other) {
  $.checkString(other);
  var receiverLength = receiver.length;
  var otherLength = other.length;
  if (otherLength > receiverLength)
    return false;
  return other === $.substring$1(receiver, receiverLength - otherLength);
};

$.ListIterator$ = function(list, T) {
  var t1 = new $.ListIterator(0, list);
  $.setRuntimeTypeInfo(t1, { 'T': T });
  return t1;
};

$._DocumentFragmentFactoryProvider_DocumentFragment$html = function(html) {
  var fragment = $._DocumentFragmentFactoryProvider_DocumentFragment();
  fragment.set$innerHTML(html);
  return fragment;
};

$.checkNum = function(value) {
  if (!(typeof value === 'number')) {
    $.checkNull(value);
    throw $.captureStackTrace($.IllegalArgumentException$(value));
  }
  return value;
};

$.JavaScriptAudioNodeEventsImpl$ = function(_ptr) {
  return new $.JavaScriptAudioNodeEventsImpl(_ptr);
};

$.addLast = function(receiver, value) {
  if (!$.isJsArray(receiver))
    return receiver.addLast$1(value);
  $.checkGrowable(receiver, 'addLast');
  receiver.push(value);
};

$.ltB = function(a, b) {
  return typeof a === 'number' && typeof b === 'number' ? a < b : $.lt$slow(a, b) === true;
};

$._HttpRequestFactoryProvider_HttpRequest = function() {
return new XMLHttpRequest();
};

$.FilteredElementList$ = function(node) {
  return new $.FilteredElementList(node, node.get$nodes());
};

$.convertDartClosureToJS = function(closure, arity) {
  if (closure == null)
    return;
  var function$ = closure.$identity;
  if (!!function$)
    return function$;
  function$ = function() {
    return $.invokeClosure.call$5(closure, $, arity, arguments[0], arguments[1]);
  };
  closure.$identity = function$;
  return function$;
};

$._FixedSizeListIterator$ = function(array, T) {
  var t1 = new $._FixedSizeListIterator($.get$length(array), array, 0);
  $.setRuntimeTypeInfo(t1, { 'T': T });
  return t1;
};

$._FrozenElementList$_wrap = function(_nodeList) {
  return new $._FrozenElementList(_nodeList);
};

$.split = function(receiver, pattern) {
  if (!(typeof receiver === 'string'))
    return receiver.split$1(pattern);
  $.checkNull(pattern);
  return $.stringSplitUnchecked(receiver, pattern);
};

$._supportsProto = function() {
  if ($._supportsProtoCache == null) {
    var tmpPrototype = $._ProtoTester$().constructor.prototype;
    if (!!(tmpPrototype.__proto__) === true) {
      tmpPrototype.__proto__ = {};
      var supportsProto = typeof tmpPrototype.get$f() === "undefined" === true && true;
    } else
      supportsProto = false;
    $._supportsProtoCache = supportsProto;
  }
  return $._supportsProtoCache;
};

$._Device_userAgent = function() {
  return $.window().get$navigator().get$userAgent();
};

$.getRange = function(receiver, start, length$) {
  if (!$.isJsArray(receiver))
    return receiver.getRange$2(start, length$);
  if (0 === length$)
    return [];
  $.checkNull(start);
  $.checkNull(length$);
  if (!(typeof start === 'number' && start === (start | 0)))
    throw $.captureStackTrace($.IllegalArgumentException$(start));
  if (!(typeof length$ === 'number' && length$ === (length$ | 0)))
    throw $.captureStackTrace($.IllegalArgumentException$(length$));
  var t1 = length$ < 0;
  if (t1)
    throw $.captureStackTrace($.IllegalArgumentException$(length$));
  if (start < 0)
    throw $.captureStackTrace($.IndexOutOfRangeException$(start));
  var end = start + length$;
  if ($.gtB(end, $.get$length(receiver)))
    throw $.captureStackTrace($.IndexOutOfRangeException$(length$));
  if (t1)
    throw $.captureStackTrace($.IllegalArgumentException$(length$));
  return receiver.slice(start, end);
};

$._DoubleLinkedQueueIterator$ = function(_sentinel, E) {
  var t1 = new $._DoubleLinkedQueueIterator(_sentinel, null);
  $.setRuntimeTypeInfo(t1, { 'E': E });
  t1._DoubleLinkedQueueIterator$1(_sentinel);
  return t1;
};

$.S = function(value) {
  var res = $.toString(value);
  if (!(typeof res === 'string'))
    throw $.captureStackTrace($.IllegalArgumentException$(value));
  return res;
};

$._componentsSetup = function() {
  $.initializeComponents(new $._componentsSetup_anon($.makeLiteralMap(['x-not-a-wrapper', new $._componentsSetup_anon0()])), true);
};

$._dynamicMetadata = function(table) {
  $dynamicMetadata = table;
};

$._dynamicMetadata0 = function() {
  if (typeof($dynamicMetadata) === 'undefined') {
    var t1 = [];
    $._dynamicMetadata(t1);
  }
  return $dynamicMetadata;
};

$.LinkedHashMapImplementation$ = function(K, V) {
  var t1 = new $.LinkedHashMapImplementation(null, null);
  $.setRuntimeTypeInfo(t1, { 'K': K, 'V': V });
  t1.LinkedHashMapImplementation$0();
  return t1;
};

$._Lists_getRange = function(a, start, length$, accumulator) {
  if (typeof a !== 'string' && (typeof a !== 'object' || a === null || a.constructor !== Array && !a.is$JavaScriptIndexingBehavior()))
    return $._Lists_getRange$bailout(1, a, start, length$, accumulator);
  if (typeof start !== 'number')
    return $._Lists_getRange$bailout(1, a, start, length$, accumulator);
  if ($.ltB(length$, 0))
    throw $.captureStackTrace($.IllegalArgumentException$('length'));
  if (start < 0)
    throw $.captureStackTrace($.IndexOutOfRangeException$(start));
  if (typeof length$ !== 'number')
    throw $.iae(length$);
  var end = start + length$;
  if (end > a.length)
    throw $.captureStackTrace($.IndexOutOfRangeException$(end));
  for (var i = start; i < end; ++i) {
    if (i !== (i | 0))
      throw $.iae(i);
    if (i < 0 || i >= a.length)
      throw $.ioore(i);
    accumulator.push(a[i]);
  }
  return accumulator;
};

$.regExpGetNative = function(regExp) {
  var r = regExp._re;
  return r == null ? regExp._re = $.regExpMakeNative(regExp, false) : r;
};

$.checkNull = function(object) {
  if (object == null)
    throw $.captureStackTrace($.NullPointerException$(null, $.CTC));
  return object;
};

$.TextTrackListEventsImpl$ = function(_ptr) {
  return new $.TextTrackListEventsImpl(_ptr);
};

$.EventsImpl$ = function(_ptr) {
  return new $.EventsImpl(_ptr);
};

$.DoubleLinkedQueue$ = function(E) {
  var t1 = new $.DoubleLinkedQueue(null);
  $.setRuntimeTypeInfo(t1, { 'E': E });
  t1.DoubleLinkedQueue$0();
  return t1;
};

$._CustomDeclaration$ = function(element) {
  var t1 = new $._CustomDeclaration(null, null, null, null);
  t1._CustomDeclaration$1(element);
  return t1;
};

$.MessagePortEventsImpl$ = function(_ptr) {
  return new $.MessagePortEventsImpl(_ptr);
};

$.checkNumbers = function(a, b) {
  if (typeof a === 'number')
    if (typeof b === 'number')
      return true;
    else {
      $.checkNull(b);
      throw $.captureStackTrace($.IllegalArgumentException$(b));
    }
  return false;
};

$._DoubleLinkedQueueEntrySentinel$ = function(E) {
  var t1 = new $._DoubleLinkedQueueEntrySentinel(null, null, null);
  $.setRuntimeTypeInfo(t1, { 'E': E });
  t1.DoubleLinkedQueueEntry$1(null);
  t1._DoubleLinkedQueueEntrySentinel$0();
  return t1;
};

$._ElementAttributeMap$ = function(_element) {
  return new $._ElementAttributeMap(_element);
};

$.lt$slow = function(a, b) {
  if ($.checkNumbers(a, b))
    return a < b;
  return a.operator$lt$1(b);
};

$._Elements_DivElement = function() {
  return $._document().$dom_createElement$1('div');
};

$.index$slow = function(a, index) {
  if (typeof a === 'string' || $.isJsArray(a)) {
    if (!(typeof index === 'number' && index === (index | 0))) {
      if (!(typeof index === 'number'))
        throw $.captureStackTrace($.IllegalArgumentException$(index));
      if (!($.truncate(index) === index))
        throw $.captureStackTrace($.IllegalArgumentException$(index));
    }
    if ($.ltB(index, 0) || $.geB(index, $.get$length(a)))
      throw $.captureStackTrace($.IndexOutOfRangeException$(index));
    return a[index];
  }
  return a.operator$index$1(index);
};

$.toString = function(value) {
  if (typeof value == "object" && value !== null)
    if ($.isJsArray(value))
      return $.Collections_collectionToString(value);
    else
      return value.toString$0();
  if (value === 0 && (1 / value) < 0)
    return '-0.0';
  if (value == null)
    return 'null';
  if (typeof value == "function")
    return 'Closure';
  return String(value);
};

$.removeLast = function(receiver) {
  if ($.isJsArray(receiver)) {
    $.checkGrowable(receiver, 'removeLast');
    if ($.get$length(receiver) === 0)
      throw $.captureStackTrace($.IndexOutOfRangeException$(-1));
    return receiver.pop();
  }
  return receiver.removeLast$0();
};

$.TextTrackCueEventsImpl$ = function(_ptr) {
  return new $.TextTrackCueEventsImpl(_ptr);
};

$.contains$2 = function(receiver, other, startIndex) {
  if (!(typeof receiver === 'string'))
    return receiver.contains$2(other, startIndex);
  $.checkNull(other);
  return $.stringContainsUnchecked(receiver, other, startIndex);
};

$.SharedWorkerContextEventsImpl$ = function(_ptr) {
  return new $.SharedWorkerContextEventsImpl(_ptr);
};

$.StringImplementation__toJsStringArray = function(strings) {
  if (typeof strings !== 'object' || strings === null || (strings.constructor !== Array || !!strings.immutable$list) && !strings.is$JavaScriptIndexingBehavior())
    return $.StringImplementation__toJsStringArray$bailout(1, strings);
  $.checkNull(strings);
  var length$ = strings.length;
  if ($.isJsArray(strings)) {
    for (var i = 0; i < length$; ++i) {
      if (i < 0 || i >= strings.length)
        throw $.ioore(i);
      var string = strings[i];
      $.checkNull(string);
      if (!(typeof string === 'string'))
        throw $.captureStackTrace($.IllegalArgumentException$(string));
    }
    var array = strings;
  } else {
    array = $.ListImplementation_List(length$);
    for (i = 0; i < length$; ++i) {
      if (i < 0 || i >= strings.length)
        throw $.ioore(i);
      string = strings[i];
      $.checkNull(string);
      if (!(typeof string === 'string'))
        throw $.captureStackTrace($.IllegalArgumentException$(string));
      if (i < 0 || i >= array.length)
        throw $.ioore(i);
      array[i] = string;
    }
  }
  return array;
};

$.initializeComponents = function(lookup, usePrototypeRewiring) {
  $._usePrototypeRewiring = usePrototypeRewiring;
  $._manager = $.CustomElementsManager$_internal(lookup);
  $.manager()._loadComponents$0();
};

$.IndexOutOfRangeException$ = function(_value) {
  return new $.IndexOutOfRangeException(_value);
};

$._AttributeClassSet$ = function(element) {
  return new $._AttributeClassSet(element);
};

$.FileWriterEventsImpl$ = function(_ptr) {
  return new $.FileWriterEventsImpl(_ptr);
};

$.charCodeAt = function(receiver, index) {
  if (typeof receiver === 'string') {
    if (index < 0)
      throw $.captureStackTrace($.IndexOutOfRangeException$(index));
    if (index >= receiver.length)
      throw $.captureStackTrace($.IndexOutOfRangeException$(index));
    return receiver.charCodeAt(index);
  } else
    return receiver.charCodeAt$1(index);
};

$.InputElementEventsImpl$ = function(_ptr) {
  return new $.InputElementEventsImpl(_ptr);
};

$.FileReaderEventsImpl$ = function(_ptr) {
  return new $.FileReaderEventsImpl(_ptr);
};

$.CustomElementsManager$_internal = function(_lookup) {
  var t1 = new $.CustomElementsManager(null, null, _lookup, null);
  t1.CustomElementsManager$_internal$1(_lookup);
  return t1;
};

$.Collections_collectionToString = function(c) {
  var result = $.StringBufferImpl$('');
  $.Collections__emitCollection(c, result, $.ListImplementation_List(null));
  return result.toString$0();
};

$.KeyValuePair$ = function(key, value, K, V) {
  var t1 = new $.KeyValuePair(key, value);
  $.setRuntimeTypeInfo(t1, { 'K': K, 'V': V });
  return t1;
};

$._FrozenCSSClassSet$ = function() {
  return new $._FrozenCSSClassSet(null);
};

$.MetaInfo$ = function(_tag, _tags, _set) {
  return new $.MetaInfo(_tag, _tags, _set);
};

$.defineProperty = function(obj, property, value) {
  Object.defineProperty(obj, property,
      {value: value, enumerable: false, writable: true, configurable: true});
};

$.dynamicFunction = function(name$) {
  var f = Object.prototype[name$];
  if (!(f == null) && !!f.methods)
    return f.methods;
  var methods = {};
  var dartMethod = Object.getPrototypeOf($.CTC29)[name$];
  if (!(dartMethod == null))
    $.propertySet(methods, 'Object', dartMethod);
  var bind = function() {return $.dynamicBind.call$4(this, name$, methods, Array.prototype.slice.call(arguments));};
  bind.methods = methods;
  $.defineProperty(Object.prototype, name$, bind);
  return methods;
};

$.print = function(obj) {
  $.Primitives_printString(obj);
};

$.checkString = function(value) {
  if (!(typeof value === 'string')) {
    $.checkNull(value);
    throw $.captureStackTrace($.IllegalArgumentException$(value));
  }
  return value;
};

$.addAll = function(receiver, collection) {
  if (!$.isJsArray(receiver))
    return receiver.addAll$1(collection);
  var iterator = $.iterator(collection);
  for (; iterator.hasNext$0() === true;)
    $.add$1(receiver, iterator.next$0());
};

$.Primitives_objectToString = function(object) {
  return 'Instance of \'' + $.S($.Primitives_objectTypeName(object)) + '\'';
};

$.Arrays_indexOf = function(a, element, startIndex, endIndex) {
  var t1 = a.length;
  if (startIndex >= t1)
    return -1;
  if (startIndex < 0)
    startIndex = 0;
  for (var i = startIndex; i < endIndex; ++i) {
    if (i < 0 || i >= t1)
      throw $.ioore(i);
    if ($.eqB(a[i], element))
      return i;
  }
  return -1;
};

$.NotificationEventsImpl$ = function(_ptr) {
  return new $.NotificationEventsImpl(_ptr);
};

$.set$length = function(receiver, newLength) {
  if ($.isJsArray(receiver)) {
    $.checkNull(newLength);
    if (!(typeof newLength === 'number' && newLength === (newLength | 0)))
      throw $.captureStackTrace($.IllegalArgumentException$(newLength));
    if (newLength < 0)
      throw $.captureStackTrace($.IndexOutOfRangeException$(newLength));
    $.checkGrowable(receiver, 'set length');
    receiver.length = newLength;
  } else
    receiver.set$length(newLength);
  return newLength;
};

$.ioore = function(index) {
  throw $.captureStackTrace($.IndexOutOfRangeException$(index));
};

$.typeNameInFirefox = function(obj) {
  var name$ = $.constructorNameFallback(obj);
  if (name$ === 'Window')
    return 'DOMWindow';
  if (name$ === 'Document')
    return 'HTMLDocument';
  if (name$ === 'XMLDocument')
    return 'Document';
  if (name$ === 'WorkerMessageEvent')
    return 'MessageEvent';
  if (name$ === 'DragEvent')
    return 'MouseEvent';
  if (name$ === 'DataTransfer')
    return 'Clipboard';
  return name$;
};

$.WorkerContextEventsImpl$ = function(_ptr) {
  return new $.WorkerContextEventsImpl(_ptr);
};

$.gt$slow = function(a, b) {
  if ($.checkNumbers(a, b))
    return a > b;
  return a.operator$gt$1(b);
};

$.hashCode = function(receiver) {
  if (typeof receiver === 'number')
    return receiver & 0x1FFFFFFF;
  if (!(typeof receiver === 'string'))
    return receiver.hashCode$0();
  var length$ = receiver.length;
  for (var hash = 0, i = 0; i < length$; ++i) {
    var hash0 = 536870911 & hash + receiver.charCodeAt(i);
    var hash1 = 536870911 & hash0 + 524287 & hash0 << 10;
    hash1 = (hash1 ^ $.shr(hash1, 6)) >>> 0;
    hash = hash1;
  }
  hash0 = 536870911 & hash + 67108863 & hash << 3;
  hash0 = (hash0 ^ $.shr(hash0, 11)) >>> 0;
  return 536870911 & hash0 + 16383 & hash0 << 15;
};

$.makeLiteralMap = function(keyValuePairs) {
  var iterator = $.iterator(keyValuePairs);
  var result = $.LinkedHashMapImplementation$();
  for (; iterator.hasNext$0() === true;)
    result.operator$indexSet$2(iterator.next$0(), iterator.next$0());
  return result;
};

$.IDBTransactionEventsImpl$ = function(_ptr) {
  return new $.IDBTransactionEventsImpl(_ptr);
};

$.startsWith = function(receiver, other) {
  $.checkString(other);
  var length$ = other.length;
  if (length$ > receiver.length)
    return false;
  return other == receiver.substring(0, length$);
};

$.toStringForNativeObject = function(obj) {
  return 'Instance of ' + $.getTypeNameOf(obj);
};

$.trim = function(receiver) {
  if (!(typeof receiver === 'string'))
    return receiver.trim$0();
  return receiver.trim();
};

$.dynamicBind = function(obj, name$, methods, arguments$) {
  var tag = $.getTypeNameOf(obj);
  var method = methods[tag];
  if (method == null && !($._dynamicMetadata0() == null))
    for (var i = 0; i < $._dynamicMetadata0().length; ++i) {
      var entry = $._dynamicMetadata0()[i];
      if (entry.get$_set()[tag]) {
        method = methods[entry.get$_tag()];
        if (!(method == null))
          break;
      }
    }
  if (method == null)
    method = methods['Object'];
  var proto = Object.getPrototypeOf(obj);
  if (method == null)
    method = function () {if (Object.getPrototypeOf(this) === proto) {throw new TypeError(name$ + " is not a function");} else {return Object.prototype[name$].apply(this, arguments);}};
  if (!proto.hasOwnProperty(name$))
    $.defineProperty(proto, name$, method);
  return method.apply(obj, arguments$);
};

$._copyProperties = function(source, dest, override) {
  for (var member in source) {
    var hasOwnProperty = Object.hasOwnProperty;
    if (member == '' || member == 'super') continue;
    if (!(Object.prototype[member] === source[member])
        && !(!override && hasOwnProperty.call(dest, member))) {
      dest[member] = source[member];
    }
  }

};

$._document = function() {
return document;
};

$.getFunctionForTypeNameOf = function() {
  if (!(typeof(navigator) === 'object'))
    return $.typeNameInChrome;
  var userAgent = navigator.userAgent;
  if ($.contains(userAgent, 'Chrome') || $.contains(userAgent, 'DumpRenderTree'))
    return $.typeNameInChrome;
  else if ($.contains(userAgent, 'Firefox'))
    return $.typeNameInFirefox;
  else if ($.contains(userAgent, 'MSIE'))
    return $.typeNameInIE;
  else if ($.contains(userAgent, 'Opera'))
    return $.typeNameInOpera;
  else if ($.contains(userAgent, 'Safari'))
    return $.typeNameInSafari;
  else
    return $.constructorNameFallback;
};

$.index = function(a, index) {
  if (typeof a == "string" || a.constructor === Array) {
    var key = index >>> 0;
    if (key === index && key < a.length)
      return a[key];
  }
  return $.index$slow(a, index);
};

$.toLowerCase = function(receiver) {
  if (!(typeof receiver === 'string'))
    return receiver.toLowerCase$0();
  return receiver.toLowerCase();
};

$.HttpRequestUploadEventsImpl$ = function(_ptr) {
  return new $.HttpRequestUploadEventsImpl(_ptr);
};

$.ListImplementation_List = function(length$, E) {
  return $.Primitives_newList(length$);
};

$.TextTrackEventsImpl$ = function(_ptr) {
  return new $.TextTrackEventsImpl(_ptr);
};

$._CssClassSet$ = function(_element) {
  return new $._CssClassSet(_element);
};

$.captureStackTrace = function(ex) {
  if (ex == null)
    ex = $.CTC0;
  var jsError = new Error();
  jsError.name = ex;
  jsError.description = ex;
  jsError.dartException = ex;
  jsError.toString = $.toStringWrapper.call$0;
  return jsError;
};

$.forEach = function(receiver, f) {
  if (!$.isJsArray(receiver))
    return receiver.forEach$1(f);
  else
    return $.Collections_forEach(receiver, f);
};

$.DOMApplicationCacheEventsImpl$ = function(_ptr) {
  return new $.DOMApplicationCacheEventsImpl(_ptr);
};

$._ElementFactoryProvider_Element$html = function(html) {
  var match = $.CTC24.firstMatch$1(html);
  if (!(match == null)) {
    var tag = $.toLowerCase(match.group$1(1));
    var parentTag = $.CTC26.containsKey$1(tag) === true ? $.CTC26.operator$index$1(tag) : 'div';
  } else {
    tag = null;
    parentTag = 'div';
  }
  var temp = $._ElementFactoryProvider_Element$tag(parentTag);
  temp.set$innerHTML(html);
  if ($.eqB($.get$length(temp.get$elements()), 1))
    var element = temp.get$elements().get$first();
  else if ($.eqB(parentTag, 'html') && $.eqB($.get$length(temp.get$elements()), 2)) {
    var t1 = temp.get$elements();
    element = $.index(t1, $.eqB(tag, 'head') ? 0 : 1);
  } else
    throw $.captureStackTrace($.IllegalArgumentException$('HTML had ' + $.S($.get$length(temp.get$elements())) + ' ' + 'top level elements but 1 expected'));
  element.remove$0();
  return element;
};

$.StackOverflowException$ = function() {
  return new $.StackOverflowException();
};

$.StringBufferImpl$ = function(content$) {
  var t1 = new $.StringBufferImpl(null, null);
  t1.StringBufferImpl$1(content$);
  return t1;
};

$.Collections_forEach = function(iterable, f) {
  for (var t1 = $.iterator(iterable); t1.hasNext$0() === true;)
    f.call$1(t1.next$0());
};

$.HashMapImplementation$ = function(K, V) {
  var t1 = new $.HashMapImplementation(null, null, null, null, null);
  $.setRuntimeTypeInfo(t1, { 'K': K, 'V': V });
  t1.HashMapImplementation$0();
  return t1;
};

$.substring$1 = function(receiver, startIndex) {
  if (!(typeof receiver === 'string'))
    return receiver.substring$1(startIndex);
  return $.substring$2(receiver, startIndex, null);
};

$.Strings_join = function(strings, separator) {
  return $.StringImplementation_join(strings, separator);
};

$.StringImplementation_join = function(strings, separator) {
  $.checkNull(strings);
  $.checkNull(separator);
  return $.stringJoinUnchecked($.StringImplementation__toJsStringArray(strings), separator);
};

$.eq = function(a, b) {
  if (a == null)
    return b == null;
  if (b == null)
    return false;
  if (typeof a === "object")
    if (!!a.operator$eq$1)
      return a.operator$eq$1(b);
  return a === b;
};

$.gtB = function(a, b) {
  return typeof a === 'number' && typeof b === 'number' ? a > b : $.gt$slow(a, b) === true;
};

$.setRuntimeTypeInfo = function(target, typeInfo) {
  if (!(target == null))
    target.builtin$typeInfo = typeInfo;
};

$.document = function() {
return document;
};

$.BodyElementEventsImpl$ = function(_ptr) {
  return new $.BodyElementEventsImpl(_ptr);
};

$.NoSuchMethodException$ = function(_receiver, _functionName, _arguments, existingArgumentNames) {
  return new $.NoSuchMethodException(_receiver, _functionName, _arguments, existingArgumentNames);
};

$.lt = function(a, b) {
  return typeof a === 'number' && typeof b === 'number' ? a < b : $.lt$slow(a, b);
};

$.unwrapException = function(ex) {
  if ("dartException" in ex)
    return ex.dartException;
  var message = ex.message;
  if (ex instanceof TypeError) {
    var type = ex.type;
    var name$ = ex.arguments ? ex.arguments[0] : "";
    if ($.eqB(type, 'property_not_function') || $.eqB(type, 'called_non_callable') || $.eqB(type, 'non_object_property_call') || $.eqB(type, 'non_object_property_load'))
      if (typeof name$ === 'string' && $.startsWith(name$, 'call$') === true)
        return $.ObjectNotClosureException$();
      else
        return $.NullPointerException$(null, $.CTC);
    else if ($.eqB(type, 'undefined_method'))
      if (typeof name$ === 'string' && $.startsWith(name$, 'call$') === true)
        return $.ObjectNotClosureException$();
      else
        return $.NoSuchMethodException$('', name$, [], null);
    var ieErrorCode = ex.number & 0xffff;
    var ieFacilityNumber = ex.number>>16 & 0x1FFF;
    if (typeof message === 'string')
      if ($.endsWith(message, 'is null') === true || $.endsWith(message, 'is undefined') === true || $.endsWith(message, 'is null or undefined') === true)
        return $.NullPointerException$(null, $.CTC);
      else {
        if ($.contains$1(message, ' is not a function') !== true)
          var t1 = ieErrorCode === 438 && ieFacilityNumber === 10;
        else
          t1 = true;
        if (t1)
          return $.NoSuchMethodException$('', '<unknown>', [], null);
      }
    return $.ExceptionImplementation$(typeof message === 'string' ? message : '');
  }
  if (ex instanceof RangeError) {
    if (typeof message === 'string' && $.contains$1(message, 'call stack') === true)
      return $.StackOverflowException$();
    return $.IllegalArgumentException$('');
  }
  if (typeof InternalError == 'function' && ex instanceof InternalError)
    if (typeof message === 'string' && message === 'too much recursion')
      return $.StackOverflowException$();
  return ex;
};

$.ceil = function(receiver) {
  return Math.ceil(receiver);
};

$.getTypeNameOf = function(obj) {
  if ($._getTypeNameOf == null)
    $._getTypeNameOf = $.getFunctionForTypeNameOf();
  return $._getTypeNameOf.call$1(obj);
};

$.SVGElementInstanceEventsImpl$ = function(_ptr) {
  return new $.SVGElementInstanceEventsImpl(_ptr);
};

$.sub = function(a, b) {
  return typeof a === 'number' && typeof b === 'number' ? a - b : $.sub$slow(a, b);
};

$._componentsMetadata = function() {
  if (typeof($componentsMetadata) === 'undefined') {
    var t1 = Object.create(null);
    $._componentsMetadata0(t1);
  }
  return $componentsMetadata;
};

$._Lists_getRange$bailout = function(state, a, start, length$, accumulator) {
  if ($.ltB(length$, 0))
    throw $.captureStackTrace($.IllegalArgumentException$('length'));
  if ($.ltB(start, 0))
    throw $.captureStackTrace($.IndexOutOfRangeException$(start));
  var end = $.add(start, length$);
  if ($.gtB(end, $.get$length(a)))
    throw $.captureStackTrace($.IndexOutOfRangeException$(end));
  for (var i = start; $.ltB(i, end); i = $.add(i, 1))
    accumulator.push($.index(a, i));
  return accumulator;
};

$.StringImplementation__toJsStringArray$bailout = function(state, strings) {
  $.checkNull(strings);
  var length$ = $.get$length(strings);
  if ($.isJsArray(strings)) {
    for (var i = 0; $.ltB(i, length$); ++i) {
      var string = $.index(strings, i);
      $.checkNull(string);
      if (!(typeof string === 'string'))
        throw $.captureStackTrace($.IllegalArgumentException$(string));
    }
    var array = strings;
  } else {
    array = $.ListImplementation_List(length$);
    for (i = 0; $.ltB(i, length$); ++i) {
      string = $.index(strings, i);
      $.checkNull(string);
      if (!(typeof string === 'string'))
        throw $.captureStackTrace($.IllegalArgumentException$(string));
      if (i < 0 || i >= array.length)
        throw $.ioore(i);
      array[i] = string;
    }
  }
  return array;
};

$.dynamicBind.call$4 = $.dynamicBind;
$.dynamicBind.$name = "dynamicBind";
$.typeNameInOpera.call$1 = $.typeNameInOpera;
$.typeNameInOpera.$name = "typeNameInOpera";
$.typeNameInIE.call$1 = $.typeNameInIE;
$.typeNameInIE.$name = "typeNameInIE";
$.typeNameInChrome.call$1 = $.typeNameInChrome;
$.typeNameInChrome.$name = "typeNameInChrome";
$.toStringWrapper.call$0 = $.toStringWrapper;
$.toStringWrapper.$name = "toStringWrapper";
$.invokeClosure.call$5 = $.invokeClosure;
$.invokeClosure.$name = "invokeClosure";
$.typeNameInSafari.call$1 = $.typeNameInSafari;
$.typeNameInSafari.$name = "typeNameInSafari";
$.typeNameInFirefox.call$1 = $.typeNameInFirefox;
$.typeNameInFirefox.$name = "typeNameInFirefox";
$.constructorNameFallback.call$1 = $.constructorNameFallback;
$.constructorNameFallback.$name = "constructorNameFallback";
Isolate.$finishClasses($$);
$$ = {};
Isolate.makeConstantList = function(list) {
  list.immutable$list = true;
  list.fixed$length = true;
  return list;
};
$.CTC = Isolate.makeConstantList([]);
$.CTC19 = new Isolate.$isolateProperties.ConstantMap(0, {}, Isolate.$isolateProperties.CTC);
$.CTC27 = Isolate.makeConstantList(['childList', 'attributes', 'characterData', 'subtree', 'attributeOldValue', 'characterDataOldValue']);
$.CTC28 = new Isolate.$isolateProperties.ConstantMap(6, {'childList': true, 'attributes': true, 'characterData': true, 'subtree': true, 'attributeOldValue': true, 'characterDataOldValue': true}, Isolate.$isolateProperties.CTC27);
$.CTC25 = Isolate.makeConstantList(['body', 'head', 'caption', 'td', 'colgroup', 'col', 'tr', 'tbody', 'tfoot', 'thead', 'track']);
$.CTC9 = new Isolate.$isolateProperties.NotImplementedException('structured clone of ArrayBufferView');
$.CTC18 = new Isolate.$isolateProperties.UnsupportedOperationException('frozen class set cannot be modified');
$.CTC15 = new Isolate.$isolateProperties._DeletedKeySentinel();
$.CTC7 = new Isolate.$isolateProperties.NotImplementedException('structured clone of FileList');
$.CTC10 = new Isolate.$isolateProperties.NotImplementedException('structured clone of other type');
$.CTC21 = new Isolate.$isolateProperties.JSSyntaxRegExp(false, false, '^\\[name=["\'][^\'"]+[\'"]\\]$');
$.CTC24 = new Isolate.$isolateProperties.JSSyntaxRegExp(false, false, '<(\\w+)');
$.CTC23 = new Isolate.$isolateProperties.JSSyntaxRegExp(false, false, '^#[_a-zA-Z]\\w*$');
$.CTC29 = new Isolate.$isolateProperties.Object();
$.CTC17 = new Isolate.$isolateProperties.IllegalArgumentException('Invalid list length');
$.CTC4 = new Isolate.$isolateProperties.NotImplementedException('structured clone of RegExp');
$.CTC5 = new Isolate.$isolateProperties.NotImplementedException('structured clone of File');
$.CTC13 = new Isolate.$isolateProperties.NotImplementedException('IDBKey containing Date');
$.CTC22 = new Isolate.$isolateProperties.JSSyntaxRegExp(false, false, '^[*a-zA-Z0-9]+$');
$.CTC11 = new Isolate.$isolateProperties.UnsupportedOperationException('Cannot removeLast on immutable List.');
$.CTC26 = new Isolate.$isolateProperties.ConstantMap(11, {'body': 'html', 'head': 'html', 'caption': 'table', 'td': 'tr', 'colgroup': 'table', 'col': 'colgroup', 'tr': 'tbody', 'tbody': 'table', 'tfoot': 'table', 'thead': 'table', 'track': 'audio'}, Isolate.$isolateProperties.CTC25);
$.CTC3 = new Isolate.$isolateProperties.NotImplementedException('structured clone of Date');
$.CTC8 = new Isolate.$isolateProperties.NotImplementedException('structured clone of ArrayBuffer');
$.CTC20 = new Isolate.$isolateProperties.IllegalAccessException();
$.CTC6 = new Isolate.$isolateProperties.NotImplementedException('structured clone of Blob');
$.CTC0 = new Isolate.$isolateProperties.NullPointerException(null, Isolate.$isolateProperties.CTC);
$.CTC2 = new Isolate.$isolateProperties._Default();
$.CTC12 = new Isolate.$isolateProperties.NoMoreElementsException();
$.CTC1 = new Isolate.$isolateProperties.UnsupportedOperationException('Cannot add to immutable List.');
$.CTC16 = new Isolate.$isolateProperties.UnsupportedOperationException('');
$.CTC14 = new Isolate.$isolateProperties.EmptyQueueException();
$.FancyDivElement__$constr = null;
$._usePrototypeRewiring = null;
$._hasShadowRoot = null;
$.Primitives_DOLLAR_CHAR_VALUE = 36;
$._getTypeNameOf = null;
$._supportsProtoCache = null;
$._cachedBrowserPrefix = null;
$._manager = null;
var $ = null;
Isolate.$finishClasses($$);
$$ = {};
Isolate = Isolate.$finishIsolateConstructor(Isolate);
var $ = new Isolate();
$.$defineNativeClass = function(cls, fields, methods) {
  var generateGetterSetter = function(field, prototype) {
  var len = field.length;
  var lastChar = field[len - 1];
  var needsGetter = lastChar == '?' || lastChar == '=';
  var needsSetter = lastChar == '!' || lastChar == '=';
  if (needsGetter || needsSetter) field = field.substring(0, len - 1);
  if (needsGetter) {
    var getterString = "return this." + field + ";";
    prototype["get$" + field] = new Function(getterString);
  }
  if (needsSetter) {
    var setterString = "this." + field + " = v;";
    prototype["set$" + field] = new Function("v", setterString);
  }
  return field;
};
  for (var i = 0; i < fields.length; i++) {
    generateGetterSetter(fields[i], methods);
  }
  for (var method in methods) {
    $.dynamicFunction(method)[cls] = methods[method];
  }
};

(function(table) {
  for (var key in table) {
    $.defineProperty(Object.prototype, key, table[key]);
  }
})({
 is$ArrayBufferViewImpl: function() { return false; },
 is$FileList: function() { return false; },
 is$Element: function() { return false; },
 is$BlobImpl: function() { return false; },
 is$ArrayBuffer: function() { return false; },
 is$JavaScriptIndexingBehavior: function() { return false; },
 is$Collection: function() { return false; },
 toString$0: function() { return $.toStringForNativeObject(this); },
 is$ArrayBufferImpl: function() { return false; },
 is$ImageData: function() { return false; },
 is$ArrayBufferView: function() { return false; },
 is$WebComponent: function() { return false; },
 is$FileListImpl: function() { return false; },
 is$FileImpl: function() { return false; },
 is$ImageDataImpl: function() { return false; },
 is$Map: function() { return false; },
 is$List: function() { return false; },
 is$File: function() { return false; },
 is$Blob: function() { return false; }
});

$.$defineNativeClass('AbstractWorker', [], {
 get$on: function() {
  if (Object.getPrototypeOf(this).hasOwnProperty('get$on')) {
  {
  return $.AbstractWorkerEventsImpl$(this);
}
  } else {
    return Object.prototype.get$on.call(this);
  }

},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('HTMLAnchorElement', ["href?", "name?", "target?", "type?"], {
 toString$0: function() {
  return this.toString();
},
 is$Element: function() { return true; }
});

$.$defineNativeClass('WebKitAnimation', ["name?"], {
});

$.$defineNativeClass('WebKitAnimationList', ["length?"], {
});

$.$defineNativeClass('HTMLAppletElement', ["name?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLAreaElement', ["href?", "target?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('ArrayBuffer', [], {
 is$ArrayBufferImpl: function() { return true; },
 is$ArrayBuffer: function() { return true; }
});

$.$defineNativeClass('ArrayBufferView', [], {
 is$ArrayBufferViewImpl: function() { return true; },
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('Attr', ["name?", "value="], {
});

$.$defineNativeClass('AudioBuffer', ["length?"], {
});

$.$defineNativeClass('AudioContext', [], {
 get$on: function() {
  return $.AudioContextEventsImpl$(this);
}
});

$.$defineNativeClass('HTMLAudioElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('AudioParam', ["name?", "value="], {
});

$.$defineNativeClass('HTMLBRElement', [], {
 clear$0: function() { return this.clear.call$0(); },
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLBaseElement', ["href?", "target?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLBaseFontElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('BatteryManager', [], {
 get$on: function() {
  return $.BatteryManagerEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('BiquadFilterNode', ["type?"], {
});

$.$defineNativeClass('Blob', ["type?"], {
 is$BlobImpl: function() { return true; },
 is$Blob: function() { return true; }
});

$.$defineNativeClass('HTMLBodyElement', [], {
 get$on: function() {
  return $.BodyElementEventsImpl$(this);
},
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLButtonElement', ["name?", "type?", "value="], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('CSSImportRule', ["href?"], {
});

$.$defineNativeClass('WebKitCSSKeyframesRule', ["name?"], {
});

$.$defineNativeClass('WebKitCSSMatrix', ["f?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('CSSRule', ["type?"], {
});

$.$defineNativeClass('CSSRuleList', ["length?"], {
});

$.$defineNativeClass('CSSStyleDeclaration', ["length?"], {
 getPropertyValue$1: function(propertyName) {
  return this.getPropertyValue(propertyName);
},
 get$clear: function() {
  return this.getPropertyValue$1('clear');
},
 clear$0: function() { return this.get$clear().call$0(); },
 get$filter: function() {
  return this.getPropertyValue$1($.S($._browserPrefix()) + 'filter');
},
 filter$1: function(arg0) { return this.get$filter().call$1(arg0); }
});

$.$defineNativeClass('CSSValueList', ["length?"], {
});

$.$defineNativeClass('HTMLCanvasElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('CharacterData', ["length?"], {
});

$.$defineNativeClass('ClientRectList', ["length?"], {
});

ConsoleImpl = (typeof console == 'undefined' ? {} : console);
ConsoleImpl.group$1 = function(arg) {
  return this.group(arg);
};
ConsoleImpl.error$1 = function(arg) {
  return this.error(arg);
};
$.$defineNativeClass('HTMLContentElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLDListElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('DOMApplicationCache', ["status?"], {
 get$on: function() {
  return $.DOMApplicationCacheEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('DOMError', ["name?"], {
});

$.$defineNativeClass('DOMException', ["name?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('DOMFileSystem', ["name?"], {
});

$.$defineNativeClass('DOMFileSystemSync', ["name?"], {
});

$.$defineNativeClass('DOMMimeType', ["type?"], {
});

$.$defineNativeClass('DOMMimeTypeArray', ["length?"], {
});

$.$defineNativeClass('DOMPlugin', ["length?", "name?"], {
});

$.$defineNativeClass('DOMPluginArray', ["length?"], {
});

$.$defineNativeClass('DOMSelection', ["type?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('DOMSettableTokenList', ["value="], {
});

$.$defineNativeClass('DOMStringList', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
  throw $.captureStackTrace($.UnsupportedOperationException$('Cannot assign element of immutable List.'));
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'String');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; }
});

$.$defineNativeClass('DOMTokenList', ["length?"], {
 add$1: function(token) {
  return this.add(token);
},
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('HTMLDataListElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('DataTransferItem', ["type?"], {
});

$.$defineNativeClass('DataTransferItemList', ["length?"], {
 add$2: function(data_OR_file, type) {
  return this.add(data_OR_file,type);
},
 add$1: function(data_OR_file) {
  return this.add(data_OR_file);
},
 clear$0: function() {
  return this.clear();
}
});

$.$defineNativeClass('DataView', [], {
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('DedicatedWorkerContext', [], {
 get$on: function() {
  return $.DedicatedWorkerContextEventsImpl$(this);
}
});

$.$defineNativeClass('HTMLDetailsElement', [], {
 open$3$async: function(arg0, arg1, arg2) { return this.open.call$3$async(arg0, arg1, arg2); },
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLDirectoryElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLDivElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLDocument', ["head?", "readyState?"], {
 get$on: function() {
  return $.DocumentEventsImpl$(this);
},
 createDocumentFragment$0: function() {
  return this.createDocumentFragment();
},
 $dom_createElement$1: function(tagName) {
  return this.createElement(tagName);
},
 $dom_getElementById$1: function(elementId) {
  return this.getElementById(elementId);
},
 $dom_getElementsByName$1: function(elementName) {
  return this.getElementsByName(elementName);
},
 $dom_getElementsByTagName$1: function(tagname) {
  return this.getElementsByTagName(tagname);
},
 $dom_querySelector$1: function(selectors) {
  return this.querySelector(selectors);
},
 $dom_querySelectorAll$1: function(selectors) {
  return this.querySelectorAll(selectors);
},
 query$1: function(selectors) {
  if ($.CTC23.hasMatch$1(selectors) === true)
    return this.$dom_getElementById$1($.substring$1(selectors, 1));
  return this.$dom_querySelector$1(selectors);
},
 queryAll$1: function(selectors) {
  if ($.CTC21.hasMatch$1(selectors) === true) {
    var mutableMatches = this.$dom_getElementsByName$1($.substring$2(selectors, 7, selectors.length - 2));
    if (typeof mutableMatches !== 'string' && (typeof mutableMatches !== 'object' || mutableMatches === null || mutableMatches.constructor !== Array && !mutableMatches.is$JavaScriptIndexingBehavior()))
      return this.queryAll$1$bailout(1, mutableMatches);
    var len = mutableMatches.length;
    var copyOfMatches = $.ListImplementation_List(len, 'Element');
    for (var i = 0; i < len; ++i) {
      if (i < 0 || i >= mutableMatches.length)
        throw $.ioore(i);
      var t1 = mutableMatches[i];
      if (i < 0 || i >= copyOfMatches.length)
        throw $.ioore(i);
      copyOfMatches[i] = t1;
    }
    return $._FrozenElementList$_wrap(copyOfMatches);
  } else if ($.CTC22.hasMatch$1(selectors) === true) {
    mutableMatches = this.$dom_getElementsByTagName$1(selectors);
    if (typeof mutableMatches !== 'string' && (typeof mutableMatches !== 'object' || mutableMatches === null || mutableMatches.constructor !== Array && !mutableMatches.is$JavaScriptIndexingBehavior()))
      return this.queryAll$1$bailout(2, mutableMatches);
    len = mutableMatches.length;
    copyOfMatches = $.ListImplementation_List(len, 'Element');
    for (i = 0; i < len; ++i) {
      if (i < 0 || i >= mutableMatches.length)
        throw $.ioore(i);
      t1 = mutableMatches[i];
      if (i < 0 || i >= copyOfMatches.length)
        throw $.ioore(i);
      copyOfMatches[i] = t1;
    }
    return $._FrozenElementList$_wrap(copyOfMatches);
  } else
    return $._FrozenElementList$_wrap(this.$dom_querySelectorAll$1(selectors));
},
 queryAll$1$bailout: function(state, env0) {
  switch (state) {
    case 1:
      mutableMatches = env0;
      break;
    case 2:
      mutableMatches = env0;
      break;
  }
  switch (state) {
    case 0:
    default:
      if (state === 1 || state === 0 && $.CTC21.hasMatch$1(selectors) === true)
        switch (state) {
          case 0:
            var mutableMatches = this.$dom_getElementsByName$1($.substring$2(selectors, 7, selectors.length - 2));
          case 1:
            state = 0;
            var len = $.get$length(mutableMatches);
            var copyOfMatches = $.ListImplementation_List(len, 'Element');
            for (var i = 0; $.ltB(i, len); ++i) {
              var t1 = $.index(mutableMatches, i);
              if (i < 0 || i >= copyOfMatches.length)
                throw $.ioore(i);
              copyOfMatches[i] = t1;
            }
            return $._FrozenElementList$_wrap(copyOfMatches);
        }
      else
        switch (state) {
          case 0:
          case 2:
            if (state === 2 || state === 0 && $.CTC22.hasMatch$1(selectors) === true)
              switch (state) {
                case 0:
                  mutableMatches = this.$dom_getElementsByTagName$1(selectors);
                case 2:
                  state = 0;
                  len = $.get$length(mutableMatches);
                  copyOfMatches = $.ListImplementation_List(len, 'Element');
                  for (i = 0; $.ltB(i, len); ++i) {
                    t1 = $.index(mutableMatches, i);
                    if (i < 0 || i >= copyOfMatches.length)
                      throw $.ioore(i);
                    copyOfMatches[i] = t1;
                  }
                  return $._FrozenElementList$_wrap(copyOfMatches);
              }
            else
              return $._FrozenElementList$_wrap(this.$dom_querySelectorAll$1(selectors));
        }
  }
},
 is$Element: function() { return true; }
});

$.$defineNativeClass('DocumentFragment', [], {
 get$elements: function() {
  if (this._elements == null)
    this._elements = $.FilteredElementList$(this);
  return this._elements;
},
 query$1: function(selectors) {
  return this.$dom_querySelector$1(selectors);
},
 queryAll$1: function(selectors) {
  return $._FrozenElementList$_wrap(this.$dom_querySelectorAll$1(selectors));
},
 set$innerHTML: function(value) {
  if (Object.getPrototypeOf(this).hasOwnProperty('set$innerHTML')) {
  {
  $.clear(this.get$nodes());
  var e = $._ElementFactoryProvider_Element$tag('div');
  e.set$innerHTML(value);
  var nodes = $.ListImplementation_List$from(e.get$nodes());
  $.addAll(this.get$nodes(), nodes);
}
  } else {
    return Object.prototype.set$innerHTML.call(this, value);
  }

},
 get$$$dom_firstElementChild: function() {
  return this.get$elements().first$0();
},
 get$$$dom_lastElementChild: function() {
  return $.last(this.get$elements());
},
 get$parent: function() {
  return;
},
 get$attributes: function() {
  return $.CTC19;
},
 get$classes: function() {
  return $._FrozenCSSClassSet$();
},
 matchesSelector$1: function(selectors) {
  return false;
},
 click$0: function() {
},
 get$click: function() { return new $.BoundClosure(this, 'click$0'); },
 set$classes: function(value) {
  throw $.captureStackTrace($.UnsupportedOperationException$('Classes can\'t be set for document fragments.'));
},
 get$on: function() {
  return $.ElementEventsImpl$(this);
},
 $dom_querySelector$1: function(selectors) {
  return this.querySelector(selectors);
},
 $dom_querySelectorAll$1: function(selectors) {
  return this.querySelectorAll(selectors);
},
 is$Element: function() { return true; }
});

$.$defineNativeClass('DocumentType', ["name?"], {
});

$.$defineNativeClass('Element', ["innerHTML!"], {
 get$attributes: function() {
  return $._ElementAttributeMap$(this);
},
 set$elements: function(value) {
  if (Object.getPrototypeOf(this).hasOwnProperty('set$elements')) {
  {
  var elements = this.get$elements();
  $.clear(elements);
  $.addAll(elements, value);
}
  } else {
    return Object.prototype.set$elements.call(this, value);
  }

},
 get$elements: function() {
  if (Object.getPrototypeOf(this).hasOwnProperty('get$elements')) {
  {
  return $._ChildrenElementList$_wrap(this);
}
  } else {
    return Object.prototype.get$elements.call(this);
  }

},
 query$1: function(selectors) {
  return this.$dom_querySelector$1(selectors);
},
 queryAll$1: function(selectors) {
  return $._FrozenElementList$_wrap(this.$dom_querySelectorAll$1(selectors));
},
 get$classes: function() {
  if (Object.getPrototypeOf(this).hasOwnProperty('get$classes')) {
  {
  return $._CssClassSet$(this);
}
  } else {
    return Object.prototype.get$classes.call(this);
  }

},
 set$classes: function(value) {
  if (Object.getPrototypeOf(this).hasOwnProperty('set$classes')) {
  {
  var classSet = this.get$classes();
  $.clear(classSet);
  $.addAll(classSet, value);
}
  } else {
    return Object.prototype.set$classes.call(this, value);
  }

},
 get$on: function() {
  if (Object.getPrototypeOf(this).hasOwnProperty('get$on')) {
  {
  return $.ElementEventsImpl$(this);
}
  } else {
    return Object.prototype.get$on.call(this);
  }

},
 get$$$dom_children: function() {
return this.children;
},
 click$0: function() {
  return this.click();
},
 get$click: function() { return new $.BoundClosure(this, 'click$0'); },
 get$$$dom_className: function() {
return this.className;
},
 set$$$dom_className: function(value) {
this.className = value;
},
 get$$$dom_firstElementChild: function() {
return this.firstElementChild;
},
 get$$$dom_lastElementChild: function() {
return this.lastElementChild;
},
 $dom_getAttribute$1: function(name) {
  return this.getAttribute(name);
},
 $dom_hasAttribute$1: function(name) {
  return this.hasAttribute(name);
},
 $dom_querySelector$1: function(selectors) {
  return this.querySelector(selectors);
},
 $dom_querySelectorAll$1: function(selectors) {
  return this.querySelectorAll(selectors);
},
 $dom_removeAttribute$1: function(name) {
  return this.removeAttribute(name);
},
 $dom_setAttribute$2: function(name, value) {
  return this.setAttribute(name,value);
},
 matchesSelector$1: function(selectors) {
  return this.webkitMatchesSelector(selectors);
},
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLEmbedElement', ["name?", "type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('Entry', ["name?"], {
});

$.$defineNativeClass('EntryArray', ["length?"], {
});

$.$defineNativeClass('EntryArraySync', ["length?"], {
});

$.$defineNativeClass('EntrySync', ["name?"], {
 remove$0: function() {
  return this.remove();
}
});

$.$defineNativeClass('Event', ["target?", "type?"], {
});

$.$defineNativeClass('EventException', ["name?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('EventSource', ["readyState?"], {
 get$on: function() {
  return $.EventSourceEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('EventTarget', [], {
 get$on: function() {
  if (Object.getPrototypeOf(this).hasOwnProperty('get$on')) {
  {
  return $.EventsImpl$(this);
}
  } else {
    return Object.prototype.get$on.call(this);
  }

},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  if (Object.getPrototypeOf(this).hasOwnProperty('$dom_addEventListener$3')) {
  {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
  } else {
    return Object.prototype.$dom_addEventListener$3.call(this, type, listener, useCapture);
  }

}
});

$.$defineNativeClass('HTMLFieldSetElement', ["elements?", "name?", "type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('File', ["name?"], {
 is$FileImpl: function() { return true; },
 is$File: function() { return true; },
 is$Blob: function() { return true; }
});

$.$defineNativeClass('FileException', ["name?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('FileList', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
  throw $.captureStackTrace($.UnsupportedOperationException$('Cannot assign element of immutable List.'));
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'File');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$FileListImpl: function() { return true; },
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$FileList: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; }
});

$.$defineNativeClass('FileReader', ["readyState?"], {
 get$on: function() {
  return $.FileReaderEventsImpl$(this);
},
 error$1: function(arg0) { return this.error.call$1(arg0); },
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('FileWriter', ["length?", "readyState?"], {
 get$on: function() {
  return $.FileWriterEventsImpl$(this);
},
 error$1: function(arg0) { return this.error.call$1(arg0); },
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('FileWriterSync', ["length?"], {
});

$.$defineNativeClass('Float32Array', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
this[index] = value
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'num');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; },
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('Float64Array', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
this[index] = value
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'num');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; },
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('HTMLFontElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLFormElement', ["length?", "name?", "target?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLFrameElement', ["name?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLFrameSetElement', [], {
 get$on: function() {
  return $.FrameSetElementEventsImpl$(this);
},
 is$Element: function() { return true; }
});

$.$defineNativeClass('GamepadList', ["length?"], {
});

$.$defineNativeClass('HTMLHRElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLAllCollection', ["length?"], {
});

$.$defineNativeClass('HTMLCollection', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
  throw $.captureStackTrace($.UnsupportedOperationException$('Cannot assign element of immutable List.'));
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'Node');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; }
});

$.$defineNativeClass('HTMLOptionsCollection', [], {
 get$length: function() {
return this.length;
},
 set$length: function(value) {
this.length = value;
},
 is$List: function() { return true; },
 is$Collection: function() { return true; }
});

$.$defineNativeClass('HTMLHeadElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLHeadingElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('History', ["length?"], {
});

$.$defineNativeClass('HTMLHtmlElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('XMLHttpRequest', ["readyState?", "response?", "status?", "statusText?"], {
 get$on: function() {
  return $.HttpRequestEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
},
 open$5: function(method, url, async, user, password) {
  return this.open(method,url,async,user,password);
},
 open$3$async: function(method,url,async) {
  return this.open(method,url,async);
},
 send$1: function(data) {
  return this.send(data);
},
 send$0: function() {
  return this.send();
}
});

$.$defineNativeClass('XMLHttpRequestException', ["name?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('XMLHttpRequestUpload', [], {
 get$on: function() {
  return $.HttpRequestUploadEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('IDBCursor', [], {
 get$key: function() {
  return $._convertNativeToDart_IDBKey(this.get$_key());
},
 get$_key: function() {
return this.key;
}
});

$.$defineNativeClass('IDBCursorWithValue', [], {
 get$value: function() {
  return $._convertNativeToDart_AcceptStructuredClone(this.get$_value());
},
 get$_value: function() {
return this.value;
}
});

$.$defineNativeClass('IDBDatabase', ["name?"], {
 get$on: function() {
  return $.IDBDatabaseEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('IDBDatabaseException', ["name?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('IDBIndex', ["name?"], {
});

$.$defineNativeClass('IDBObjectStore', ["name?"], {
 add$2: function(value, key) {
  if (!$.eqB($.CTC2, key))
    return this._add_1$2($._convertDartToNative_SerializedScriptValue(value), key);
  return this._add_2$1($._convertDartToNative_SerializedScriptValue(value));
},
 add$1: function(value) {
  return this.add$2(value,Isolate.$isolateProperties.CTC2)
},
 _add_1$2: function(value, key) {
  return this.add(value,key);
},
 _add_2$1: function(value) {
  return this.add(value);
},
 clear$0: function() {
  return this.clear();
}
});

$.$defineNativeClass('IDBOpenDBRequest', [], {
 get$on: function() {
  return $.IDBOpenDBRequestEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('IDBRequest', ["readyState?"], {
 get$on: function() {
  if (Object.getPrototypeOf(this).hasOwnProperty('get$on')) {
  {
  return $.IDBRequestEventsImpl$(this);
}
  } else {
    return Object.prototype.get$on.call(this);
  }

},
 error$1: function(arg0) { return this.error.call$1(arg0); },
 $dom_addEventListener$3: function(type, listener, useCapture) {
  if (Object.getPrototypeOf(this).hasOwnProperty('$dom_addEventListener$3')) {
  {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
  } else {
    return Object.prototype.$dom_addEventListener$3.call(this, type, listener, useCapture);
  }

}
});

$.$defineNativeClass('IDBTransaction', [], {
 get$on: function() {
  return $.IDBTransactionEventsImpl$(this);
},
 error$1: function(arg0) { return this.error.call$1(arg0); },
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('IDBVersionChangeRequest', [], {
 get$on: function() {
  return $.IDBVersionChangeRequestEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('HTMLIFrameElement', ["name?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('ImageData', [], {
 is$ImageDataImpl: function() { return true; },
 is$ImageData: function() { return true; }
});

$.$defineNativeClass('HTMLImageElement', ["name?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLInputElement', ["name?", "type?", "value="], {
 get$on: function() {
  return $.InputElementEventsImpl$(this);
},
 is$Element: function() { return true; }
});

$.$defineNativeClass('Int16Array', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
this[index] = value
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'int');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; },
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('Int32Array', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
this[index] = value
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'int');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; },
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('Int8Array', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
this[index] = value
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'int');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; },
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('JavaScriptAudioNode', [], {
 get$on: function() {
  return $.JavaScriptAudioNodeEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('JavaScriptCallFrame', ["type?"], {
});

$.$defineNativeClass('HTMLKeygenElement', ["name?", "type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLLIElement', ["type?", "value="], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLLabelElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLLegendElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLLinkElement', ["href?", "target?", "type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('LocalMediaStream', [], {
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('Location', ["href?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('HTMLMapElement', ["name?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLMarqueeElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('MediaController', [], {
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('HTMLMediaElement', ["readyState?"], {
 get$on: function() {
  return $.MediaElementEventsImpl$(this);
},
 error$1: function(arg0) { return this.error.call$1(arg0); },
 is$Element: function() { return true; }
});

$.$defineNativeClass('MediaList', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
  throw $.captureStackTrace($.UnsupportedOperationException$('Cannot assign element of immutable List.'));
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'String');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; }
});

$.$defineNativeClass('MediaSource', ["readyState?"], {
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('MediaStream', ["readyState?"], {
 get$on: function() {
  return $.MediaStreamEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  if (Object.getPrototypeOf(this).hasOwnProperty('$dom_addEventListener$3')) {
  {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
  } else {
    return Object.prototype.$dom_addEventListener$3.call(this, type, listener, useCapture);
  }

}
});

$.$defineNativeClass('MediaStreamList', ["length?"], {
});

$.$defineNativeClass('MediaStreamTrack', ["readyState?"], {
 get$on: function() {
  return $.MediaStreamTrackEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('MediaStreamTrackList', ["length?"], {
 get$on: function() {
  return $.MediaStreamTrackListEventsImpl$(this);
},
 add$1: function(track) {
  return this.add(track);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('HTMLMenuElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('MessagePort', [], {
 get$on: function() {
  return $.MessagePortEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('HTMLMetaElement', ["name?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLMeterElement', ["value="], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLModElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('MutationObserver', [], {
 observe$9: function(target, options, childList, attributes, characterData, subtree, attributeOldValue, characterDataOldValue, attributeFilter) {
  var parsedOptions = {};
  if (!(options == null))
    $.forEach(options, new $.MutationObserverImpl_observe_anon(parsedOptions));
  var t1 = new $.MutationObserverImpl_observe_override(parsedOptions);
  t1.call$2('childList', childList);
  t1.call$2('attributes', attributes);
  t1.call$2('characterData', characterData);
  t1.call$2('subtree', subtree);
  t1.call$2('attributeOldValue', attributeOldValue);
  t1.call$2('characterDataOldValue', characterDataOldValue);
  if (!(attributeFilter == null))
    t1.call$2('attributeFilter', attributeFilter);
  this._call$2(target, parsedOptions);
},
 observe$3$attributeOldValue$attributes: function(target,attributeOldValue,attributes) {
  return this.observe$9(target,null,null,attributes,null,null,attributeOldValue,null,null)
},
 observe$3$childList$subtree: function(target,childList,subtree) {
  return this.observe$9(target,null,childList,null,null,subtree,null,null,null)
},
 _call$2: function(target, options) {
  return this.observe(target,options);
}
});

$.$defineNativeClass('MutationRecord', ["addedNodes?", "attributeName?", "oldValue?", "removedNodes?", "target?", "type?"], {
});

$.$defineNativeClass('NamedNodeMap', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
  throw $.captureStackTrace($.UnsupportedOperationException$('Cannot assign element of immutable List.'));
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'Node');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; }
});

$.$defineNativeClass('Navigator', ["userAgent?"], {
});

$.$defineNativeClass('Node', [], {
 get$nodes: function() {
  return $._ChildNodeListLazy$(this);
},
 remove$0: function() {
  if (!(this.get$parent() == null))
    this.get$parent().$dom_removeChild$1(this);
  return this;
},
 replaceWith$1: function(otherNode) {
  try {
    var parent$ = this.get$parent();
    parent$.$dom_replaceChild$2(otherNode, this);
  } catch (exception) {
    $.unwrapException(exception);
  }

  return this;
},
 get$$$dom_attributes: function() {
return this.attributes;
},
 get$$$dom_childNodes: function() {
return this.childNodes;
},
 get$parent: function() {
  if (Object.getPrototypeOf(this).hasOwnProperty('get$parent')) {
  {
return this.parentNode;
}
  } else {
    return Object.prototype.get$parent.call(this);
  }

},
 set$text: function(value) {
this.textContent = value;
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
},
 $dom_appendChild$1: function(newChild) {
  return this.appendChild(newChild);
},
 clone$1: function(deep) {
  return this.cloneNode(deep);
},
 $dom_removeChild$1: function(oldChild) {
  return this.removeChild(oldChild);
},
 $dom_replaceChild$2: function(newChild, oldChild) {
  return this.replaceChild(newChild,oldChild);
}
});

$.$defineNativeClass('NodeIterator', [], {
 filter$1: function(arg0) { return this.filter.call$1(arg0); }
});

$.$defineNativeClass('NodeList', ["length?"], {
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'Node');
},
 add$1: function(value) {
  this._parent.$dom_appendChild$1(value);
},
 addLast$1: function(value) {
  this._parent.$dom_appendChild$1(value);
},
 addAll$1: function(collection) {
  for (var t1 = $.iterator(collection), t2 = this._parent; t1.hasNext$0() === true;)
    t2.$dom_appendChild$1(t1.next$0());
},
 removeLast$0: function() {
  var result = this.last$0();
  if (!(result == null))
    this._parent.$dom_removeChild$1(result);
  return result;
},
 clear$0: function() {
  this._parent.set$text('');
},
 operator$indexSet$2: function(index, value) {
  this._parent.$dom_replaceChild$2(value, this.operator$index$1(index));
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._NodeListWrapper$($._Collections_filter(this, [], f));
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 get$first: function() {
  return this.operator$index$1(0);
},
 first$0: function() { return this.get$first().call$0(); },
 getRange$2: function(start, rangeLength) {
  return $._NodeListWrapper$($._Lists_getRange(this, start, rangeLength, []));
},
 operator$index$1: function(index) {
return this[index];
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; }
});

$.$defineNativeClass('Notification', [], {
 get$on: function() {
  return $.NotificationEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('HTMLOListElement', ["type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLObjectElement', ["name?", "type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLOptGroupElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLOptionElement', ["value="], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('Oscillator', ["type?"], {
});

$.$defineNativeClass('HTMLOutputElement', ["name?", "type?", "value="], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLParagraphElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLParamElement', ["name?", "type?", "value="], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('PeerConnection00', ["readyState?"], {
 get$on: function() {
  return $.PeerConnection00EventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('PerformanceNavigation', ["type?"], {
});

$.$defineNativeClass('HTMLPreElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('ProcessingInstruction', ["target?"], {
});

$.$defineNativeClass('HTMLProgressElement', ["value="], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLQuoteElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('RTCPeerConnection', [], {
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('RadioNodeList', ["value="], {
 is$List: function() { return true; },
 is$Collection: function() { return true; }
});

$.$defineNativeClass('Range', [], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('RangeException', ["name?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('SQLResultSetRowList', ["length?"], {
});

$.$defineNativeClass('SVGAElement', ["target?", "href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGAltGlyphDefElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGAltGlyphElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGAltGlyphItemElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGAngle', ["value="], {
});

$.$defineNativeClass('SVGAnimateColorElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGAnimateElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGAnimateMotionElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGAnimateTransformElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGAnimationElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGCircleElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGClipPathElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGComponentTransferFunctionElement', ["type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGCursorElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGDefsElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGDescElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGDocument', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGElement', [], {
 get$classes: function() {
  if (this.get$_cssClassSet() == null)
    this.set$_cssClassSet($._AttributeClassSet$(this.get$_ptr()));
  return this.get$_cssClassSet();
},
 get$elements: function() {
  return $.FilteredElementList$(this);
},
 set$elements: function(value) {
  var elements = this.get$elements();
  $.clear(elements);
  $.addAll(elements, value);
},
 set$innerHTML: function(svg) {
  var container = $._ElementFactoryProvider_Element$tag('div');
  container.set$innerHTML('<svg version="1.1">' + $.S(svg) + '</svg>');
  this.set$elements(container.get$elements().get$first().get$elements());
},
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGElementInstance', [], {
 get$on: function() {
  return $.SVGElementInstanceEventsImpl$(this);
}
});

$.$defineNativeClass('SVGElementInstanceList', ["length?"], {
});

$.$defineNativeClass('SVGEllipseElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGException', ["name?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('SVGFEBlendElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEColorMatrixElement', ["type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEComponentTransferElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFECompositeElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEConvolveMatrixElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEDiffuseLightingElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEDisplacementMapElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEDistantLightElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEDropShadowElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEFloodElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEFuncAElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEFuncBElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEFuncGElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEFuncRElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEGaussianBlurElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEImageElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEMergeElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEMergeNodeElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEMorphologyElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEOffsetElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFEPointLightElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFESpecularLightingElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFESpotLightElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFETileElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFETurbulenceElement', ["type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFilterElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFontElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFontFaceElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFontFaceFormatElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFontFaceNameElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFontFaceSrcElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGFontFaceUriElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGForeignObjectElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGGElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGGlyphElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGGlyphRefElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGGradientElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGHKernElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGImageElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGLength', ["value="], {
});

$.$defineNativeClass('SVGLengthList', [], {
 clear$0: function() {
  return this.clear();
}
});

$.$defineNativeClass('SVGLineElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGLinearGradientElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGMPathElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGMarkerElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGMaskElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGMatrix', ["f?"], {
});

$.$defineNativeClass('SVGMetadataElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGMissingGlyphElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGNumber', ["value="], {
});

$.$defineNativeClass('SVGNumberList', [], {
 clear$0: function() {
  return this.clear();
}
});

$.$defineNativeClass('SVGPathElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGPathSegList', [], {
 clear$0: function() {
  return this.clear();
}
});

$.$defineNativeClass('SVGPatternElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGPointList', [], {
 clear$0: function() {
  return this.clear();
}
});

$.$defineNativeClass('SVGPolygonElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGPolylineElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGRadialGradientElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGRectElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGSVGElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGScriptElement', ["type?", "href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGSetElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGStopElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGStringList', [], {
 clear$0: function() {
  return this.clear();
}
});

$.$defineNativeClass('SVGStyleElement', ["type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGSwitchElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGSymbolElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGTRefElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGTSpanElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGTextContentElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGTextElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGTextPathElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGTextPositioningElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGTitleElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGTransform', ["type?"], {
});

$.$defineNativeClass('SVGTransformList', [], {
 clear$0: function() {
  return this.clear();
}
});

$.$defineNativeClass('SVGUseElement', ["href?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGVKernElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SVGViewElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLScriptElement', ["type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('ScriptProfile', ["head?"], {
});

$.$defineNativeClass('HTMLSelectElement', ["length=", "name?", "type?", "value="], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLShadowElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('ShadowRoot', ["applyAuthorStyles!", "innerHTML!", "resetStyleInheritance!"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SharedWorkerContext', ["name?"], {
 get$on: function() {
  return $.SharedWorkerContextEventsImpl$(this);
}
});

$.$defineNativeClass('SourceBufferList', ["length?"], {
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('HTMLSourceElement', ["type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLSpanElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('SpeechGrammarList', ["length?"], {
});

$.$defineNativeClass('SpeechInputResultList', ["length?"], {
});

$.$defineNativeClass('SpeechRecognition', [], {
 get$on: function() {
  return $.SpeechRecognitionEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('SpeechRecognitionResult', ["length?"], {
});

$.$defineNativeClass('SpeechRecognitionResultList', ["length?"], {
});

$.$defineNativeClass('Storage', [], {
 containsKey$1: function(key) {
  return !(this.$dom_getItem$1(key) == null);
},
 operator$index$1: function(key) {
  return this.$dom_getItem$1(key);
},
 operator$indexSet$2: function(key, value) {
  return this.$dom_setItem$2(key, value);
},
 clear$0: function() {
  return this.$dom_clear$0();
},
 forEach$1: function(f) {
  for (var i = 0; true; ++i) {
    var key = this.$dom_key$1(i);
    if (key == null)
      return;
    f.call$2(key, this.operator$index$1(key));
  }
},
 getValues$0: function() {
  var values = [];
  this.forEach$1(new $.StorageImpl_getValues_anon(values));
  return values;
},
 get$length: function() {
  return this.get$$$dom_length();
},
 isEmpty$0: function() {
  return this.$dom_key$1(0) == null;
},
 get$$$dom_length: function() {
return this.length;
},
 $dom_clear$0: function() {
  return this.clear();
},
 $dom_getItem$1: function(key) {
  return this.getItem(key);
},
 $dom_key$1: function(index) {
  return this.key(index);
},
 $dom_setItem$2: function(key, data) {
  return this.setItem(key,data);
},
 is$Map: function() { return true; }
});

$.$defineNativeClass('StorageEvent', ["key?", "oldValue?"], {
});

$.$defineNativeClass('HTMLStyleElement', ["type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('StyleMedia', ["type?"], {
});

$.$defineNativeClass('StyleSheet', ["href?", "type?"], {
});

$.$defineNativeClass('StyleSheetList', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
  throw $.captureStackTrace($.UnsupportedOperationException$('Cannot assign element of immutable List.'));
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'StyleSheet');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; }
});

$.$defineNativeClass('HTMLTableCaptionElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLTableCellElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLTableColElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLTableElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLTableRowElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLTableSectionElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLTextAreaElement', ["name?", "type?", "value="], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('TextTrack', [], {
 get$on: function() {
  return $.TextTrackEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('TextTrackCue', ["text!"], {
 get$on: function() {
  return $.TextTrackCueEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('TextTrackCueList', ["length?"], {
});

$.$defineNativeClass('TextTrackList', ["length?"], {
 get$on: function() {
  return $.TextTrackListEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('TimeRanges', ["length?"], {
});

$.$defineNativeClass('HTMLTitleElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('Touch', ["target?"], {
});

$.$defineNativeClass('TouchList', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
  throw $.captureStackTrace($.UnsupportedOperationException$('Cannot assign element of immutable List.'));
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'Touch');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; }
});

$.$defineNativeClass('HTMLTrackElement', ["readyState?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('TreeWalker', [], {
 filter$1: function(arg0) { return this.filter.call$1(arg0); }
});

$.$defineNativeClass('HTMLUListElement', ["type?"], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('Uint16Array', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
this[index] = value
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'int');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; },
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('Uint32Array', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
this[index] = value
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'int');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; },
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('Uint8Array', ["length?"], {
 operator$index$1: function(index) {
return this[index];
},
 operator$indexSet$2: function(index, value) {
this[index] = value
},
 iterator$0: function() {
  return $._FixedSizeListIterator$(this, 'int');
},
 add$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addLast$1: function(value) {
  throw $.captureStackTrace($.CTC1);
},
 addAll$1: function(collection) {
  throw $.captureStackTrace($.CTC1);
},
 forEach$1: function(f) {
  return $._Collections_forEach(this, f);
},
 filter$1: function(f) {
  return $._Collections_filter(this, [], f);
},
 isEmpty$0: function() {
  return $.eq($.get$length(this), 0);
},
 last$0: function() {
  return this.operator$index$1($.sub($.get$length(this), 1));
},
 removeLast$0: function() {
  throw $.captureStackTrace($.CTC11);
},
 getRange$2: function(start, rangeLength) {
  return $._Lists_getRange(this, start, rangeLength, []);
},
 is$JavaScriptIndexingBehavior: function() { return true; },
 is$List: function() { return true; },
 is$Collection: function() { return true; },
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('Uint8ClampedArray', [], {
 is$List: function() { return true; },
 is$Collection: function() { return true; },
 is$ArrayBufferView: function() { return true; }
});

$.$defineNativeClass('HTMLUnknownElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('HTMLVideoElement', [], {
 is$Element: function() { return true; }
});

$.$defineNativeClass('WebGLActiveInfo', ["name?", "type?"], {
});

$.$defineNativeClass('WebKitNamedFlow', ["name?"], {
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('WebSocket', ["readyState?"], {
 get$on: function() {
  return $.WebSocketEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('DOMWindow', ["console?", "length?", "name?", "navigator?", "parent?", "status?"], {
 get$on: function() {
  return $.WindowEventsImpl$(this);
},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('Worker', [], {
 get$on: function() {
  return $.WorkerEventsImpl$(this);
}
});

$.$defineNativeClass('WorkerContext', ["navigator?"], {
 get$on: function() {
  if (Object.getPrototypeOf(this).hasOwnProperty('get$on')) {
  {
  return $.WorkerContextEventsImpl$(this);
}
  } else {
    return Object.prototype.get$on.call(this);
  }

},
 $dom_addEventListener$3: function(type, listener, useCapture) {
  return this.addEventListener(type,$.convertDartClosureToJS(listener, 1),useCapture);
}
});

$.$defineNativeClass('WorkerLocation', ["href?"], {
 toString$0: function() {
  return this.toString();
}
});

$.$defineNativeClass('WorkerNavigator', ["userAgent?"], {
});

$.$defineNativeClass('XPathException', ["name?"], {
 toString$0: function() {
  return this.toString();
}
});

// 315 dynamic classes.
// 375 classes
// 36 !leaf
(function(){
  var v0/*class(SVGTextPositioningElementImpl)*/ = 'SVGTextPositioningElement|SVGTextElement|SVGTSpanElement|SVGTRefElement|SVGAltGlyphElement|SVGTextElement|SVGTSpanElement|SVGTRefElement|SVGAltGlyphElement';
  var v1/*class(Uint8ArrayImpl)*/ = 'Uint8Array|Uint8ClampedArray|Uint8ClampedArray';
  var v2/*class(SVGTextContentElementImpl)*/ = [v0/*class(SVGTextPositioningElementImpl)*/,v0/*class(SVGTextPositioningElementImpl)*/,'SVGTextContentElement|SVGTextPathElement|SVGTextPathElement'].join('|');
  var v3/*class(SVGGradientElementImpl)*/ = 'SVGGradientElement|SVGRadialGradientElement|SVGLinearGradientElement|SVGRadialGradientElement|SVGLinearGradientElement';
  var v4/*class(SVGComponentTransferFunctionElementImpl)*/ = 'SVGComponentTransferFunctionElement|SVGFEFuncRElement|SVGFEFuncGElement|SVGFEFuncBElement|SVGFEFuncAElement|SVGFEFuncRElement|SVGFEFuncGElement|SVGFEFuncBElement|SVGFEFuncAElement';
  var v5/*class(SVGAnimationElementImpl)*/ = 'SVGAnimationElement|SVGSetElement|SVGAnimateTransformElement|SVGAnimateMotionElement|SVGAnimateElement|SVGAnimateColorElement|SVGSetElement|SVGAnimateTransformElement|SVGAnimateMotionElement|SVGAnimateElement|SVGAnimateColorElement';
  var v6/*class(SVGElementImpl)*/ = [v2/*class(SVGTextContentElementImpl)*/,v3/*class(SVGGradientElementImpl)*/,v4/*class(SVGComponentTransferFunctionElementImpl)*/,v5/*class(SVGAnimationElementImpl)*/,v2/*class(SVGTextContentElementImpl)*/,v3/*class(SVGGradientElementImpl)*/,v4/*class(SVGComponentTransferFunctionElementImpl)*/,v5/*class(SVGAnimationElementImpl)*/,'SVGElement|SVGViewElement|SVGVKernElement|SVGUseElement|SVGTitleElement|SVGSymbolElement|SVGSwitchElement|SVGStyleElement|SVGStopElement|SVGScriptElement|SVGSVGElement|SVGRectElement|SVGPolylineElement|SVGPolygonElement|SVGPatternElement|SVGPathElement|SVGMissingGlyphElement|SVGMetadataElement|SVGMaskElement|SVGMarkerElement|SVGMPathElement|SVGLineElement|SVGImageElement|SVGHKernElement|SVGGlyphRefElement|SVGGlyphElement|SVGGElement|SVGForeignObjectElement|SVGFontFaceUriElement|SVGFontFaceSrcElement|SVGFontFaceNameElement|SVGFontFaceFormatElement|SVGFontFaceElement|SVGFontElement|SVGFilterElement|SVGFETurbulenceElement|SVGFETileElement|SVGFESpotLightElement|SVGFESpecularLightingElement|SVGFEPointLightElement|SVGFEOffsetElement|SVGFEMorphologyElement|SVGFEMergeNodeElement|SVGFEMergeElement|SVGFEImageElement|SVGFEGaussianBlurElement|SVGFEFloodElement|SVGFEDropShadowElement|SVGFEDistantLightElement|SVGFEDisplacementMapElement|SVGFEDiffuseLightingElement|SVGFEConvolveMatrixElement|SVGFECompositeElement|SVGFEComponentTransferElement|SVGFEColorMatrixElement|SVGFEBlendElement|SVGEllipseElement|SVGDescElement|SVGDefsElement|SVGCursorElement|SVGClipPathElement|SVGCircleElement|SVGAltGlyphItemElement|SVGAltGlyphDefElement|SVGAElement|SVGViewElement|SVGVKernElement|SVGUseElement|SVGTitleElement|SVGSymbolElement|SVGSwitchElement|SVGStyleElement|SVGStopElement|SVGScriptElement|SVGSVGElement|SVGRectElement|SVGPolylineElement|SVGPolygonElement|SVGPatternElement|SVGPathElement|SVGMissingGlyphElement|SVGMetadataElement|SVGMaskElement|SVGMarkerElement|SVGMPathElement|SVGLineElement|SVGImageElement|SVGHKernElement|SVGGlyphRefElement|SVGGlyphElement|SVGGElement|SVGForeignObjectElement|SVGFontFaceUriElement|SVGFontFaceSrcElement|SVGFontFaceNameElement|SVGFontFaceFormatElement|SVGFontFaceElement|SVGFontElement|SVGFilterElement|SVGFETurbulenceElement|SVGFETileElement|SVGFESpotLightElement|SVGFESpecularLightingElement|SVGFEPointLightElement|SVGFEOffsetElement|SVGFEMorphologyElement|SVGFEMergeNodeElement|SVGFEMergeElement|SVGFEImageElement|SVGFEGaussianBlurElement|SVGFEFloodElement|SVGFEDropShadowElement|SVGFEDistantLightElement|SVGFEDisplacementMapElement|SVGFEDiffuseLightingElement|SVGFEConvolveMatrixElement|SVGFECompositeElement|SVGFEComponentTransferElement|SVGFEColorMatrixElement|SVGFEBlendElement|SVGEllipseElement|SVGDescElement|SVGDefsElement|SVGCursorElement|SVGClipPathElement|SVGCircleElement|SVGAltGlyphItemElement|SVGAltGlyphDefElement|SVGAElement'].join('|');
  var v7/*class(MediaElementImpl)*/ = 'HTMLMediaElement|HTMLVideoElement|HTMLAudioElement|HTMLVideoElement|HTMLAudioElement';
  var v8/*class(DivElementImpl)*/ = 'HTMLDivElement|FancyDivElement';
  var v9/*class(ElementImpl)*/ = [v6/*class(SVGElementImpl)*/,v7/*class(MediaElementImpl)*/,v8/*class(DivElementImpl)*/,v6/*class(SVGElementImpl)*/,v7/*class(MediaElementImpl)*/,v8/*class(DivElementImpl)*/,'Element|HTMLUnknownElement|HTMLUListElement|HTMLTrackElement|HTMLTitleElement|HTMLTextAreaElement|HTMLTableSectionElement|HTMLTableRowElement|HTMLTableElement|HTMLTableColElement|HTMLTableCellElement|HTMLTableCaptionElement|HTMLStyleElement|HTMLSpanElement|HTMLSourceElement|HTMLShadowElement|HTMLSelectElement|HTMLScriptElement|HTMLQuoteElement|HTMLProgressElement|HTMLPreElement|HTMLParamElement|HTMLParagraphElement|HTMLOutputElement|HTMLOptionElement|HTMLOptGroupElement|HTMLObjectElement|HTMLOListElement|HTMLModElement|HTMLMeterElement|HTMLMetaElement|HTMLMenuElement|HTMLMarqueeElement|HTMLMapElement|HTMLLinkElement|HTMLLegendElement|HTMLLabelElement|HTMLLIElement|HTMLKeygenElement|HTMLInputElement|HTMLImageElement|HTMLIFrameElement|HTMLHtmlElement|HTMLHeadingElement|HTMLHeadElement|HTMLHRElement|HTMLFrameSetElement|HTMLFrameElement|HTMLFormElement|HTMLFontElement|HTMLFieldSetElement|HTMLEmbedElement|HTMLDirectoryElement|HTMLDetailsElement|HTMLDataListElement|HTMLDListElement|HTMLContentElement|HTMLCanvasElement|HTMLButtonElement|HTMLBodyElement|HTMLBaseFontElement|HTMLBaseElement|HTMLBRElement|HTMLAreaElement|HTMLAppletElement|HTMLAnchorElement|HTMLElement|HTMLUnknownElement|HTMLUListElement|HTMLTrackElement|HTMLTitleElement|HTMLTextAreaElement|HTMLTableSectionElement|HTMLTableRowElement|HTMLTableElement|HTMLTableColElement|HTMLTableCellElement|HTMLTableCaptionElement|HTMLStyleElement|HTMLSpanElement|HTMLSourceElement|HTMLShadowElement|HTMLSelectElement|HTMLScriptElement|HTMLQuoteElement|HTMLProgressElement|HTMLPreElement|HTMLParamElement|HTMLParagraphElement|HTMLOutputElement|HTMLOptionElement|HTMLOptGroupElement|HTMLObjectElement|HTMLOListElement|HTMLModElement|HTMLMeterElement|HTMLMetaElement|HTMLMenuElement|HTMLMarqueeElement|HTMLMapElement|HTMLLinkElement|HTMLLegendElement|HTMLLabelElement|HTMLLIElement|HTMLKeygenElement|HTMLInputElement|HTMLImageElement|HTMLIFrameElement|HTMLHtmlElement|HTMLHeadingElement|HTMLHeadElement|HTMLHRElement|HTMLFrameSetElement|HTMLFrameElement|HTMLFormElement|HTMLFontElement|HTMLFieldSetElement|HTMLEmbedElement|HTMLDirectoryElement|HTMLDetailsElement|HTMLDataListElement|HTMLDListElement|HTMLContentElement|HTMLCanvasElement|HTMLButtonElement|HTMLBodyElement|HTMLBaseFontElement|HTMLBaseElement|HTMLBRElement|HTMLAreaElement|HTMLAppletElement|HTMLAnchorElement|HTMLElement'].join('|');
  var v10/*class(DocumentFragmentImpl)*/ = 'DocumentFragment|ShadowRoot|ShadowRoot';
  var v11/*class(DocumentImpl)*/ = 'HTMLDocument|SVGDocument|SVGDocument';
  var v12/*class(CharacterDataImpl)*/ = 'CharacterData|Text|CDATASection|CDATASection|Comment|Text|CDATASection|CDATASection|Comment';
  var v13/*class(WorkerContextImpl)*/ = 'WorkerContext|SharedWorkerContext|DedicatedWorkerContext|SharedWorkerContext|DedicatedWorkerContext';
  var v14/*class(NodeImpl)*/ = [v9/*class(ElementImpl)*/,v10/*class(DocumentFragmentImpl)*/,v11/*class(DocumentImpl)*/,v12/*class(CharacterDataImpl)*/,v9/*class(ElementImpl)*/,v10/*class(DocumentFragmentImpl)*/,v11/*class(DocumentImpl)*/,v12/*class(CharacterDataImpl)*/,'Node|ProcessingInstruction|Notation|EntityReference|Entity|DocumentType|Attr|ProcessingInstruction|Notation|EntityReference|Entity|DocumentType|Attr'].join('|');
  var v15/*class(MediaStreamImpl)*/ = 'MediaStream|LocalMediaStream|LocalMediaStream';
  var v16/*class(IDBRequestImpl)*/ = 'IDBRequest|IDBVersionChangeRequest|IDBOpenDBRequest|IDBVersionChangeRequest|IDBOpenDBRequest';
  var v17/*class(AbstractWorkerImpl)*/ = 'AbstractWorker|Worker|SharedWorker|Worker|SharedWorker';
  var table = [
    // [dynamic-dispatch-tag, tags of classes implementing dynamic-dispatch-tag]
    ['SVGGradientElement', v3/*class(SVGGradientElementImpl)*/],
    ['SVGTextPositioningElement', v0/*class(SVGTextPositioningElementImpl)*/],
    ['SVGTextContentElement', v2/*class(SVGTextContentElementImpl)*/],
    ['StyleSheet', 'StyleSheet|CSSStyleSheet|CSSStyleSheet'],
    ['AbstractWorker', v17/*class(AbstractWorkerImpl)*/],
    ['Uint8Array', v1/*class(Uint8ArrayImpl)*/],
    ['ArrayBufferView', [v1/*class(Uint8ArrayImpl)*/,v1/*class(Uint8ArrayImpl)*/,'ArrayBufferView|Uint32Array|Uint16Array|Int8Array|Int32Array|Int16Array|Float64Array|Float32Array|DataView|Uint32Array|Uint16Array|Int8Array|Int32Array|Int16Array|Float64Array|Float32Array|DataView'].join('|')],
    ['AudioParam', 'AudioParam|AudioGain|AudioGain'],
    ['Blob', 'Blob|File|File'],
    ['CSSRule', 'CSSRule|CSSUnknownRule|CSSStyleRule|CSSPageRule|CSSMediaRule|WebKitCSSKeyframesRule|WebKitCSSKeyframeRule|CSSImportRule|CSSFontFaceRule|CSSCharsetRule|CSSUnknownRule|CSSStyleRule|CSSPageRule|CSSMediaRule|WebKitCSSKeyframesRule|WebKitCSSKeyframeRule|CSSImportRule|CSSFontFaceRule|CSSCharsetRule'],
    ['WorkerContext', v13/*class(WorkerContextImpl)*/],
    ['CSSValueList', 'CSSValueList|WebKitCSSFilterValue|WebKitCSSTransformValue|WebKitCSSFilterValue|WebKitCSSTransformValue'],
    ['CharacterData', v12/*class(CharacterDataImpl)*/],
    ['DOMTokenList', 'DOMTokenList|DOMSettableTokenList|DOMSettableTokenList'],
    ['HTMLDivElement', v8/*class(DivElementImpl)*/],
    ['HTMLDocument', v11/*class(DocumentImpl)*/],
    ['DocumentFragment', v10/*class(DocumentFragmentImpl)*/],
    ['SVGComponentTransferFunctionElement', v4/*class(SVGComponentTransferFunctionElementImpl)*/],
    ['SVGAnimationElement', v5/*class(SVGAnimationElementImpl)*/],
    ['SVGElement', v6/*class(SVGElementImpl)*/],
    ['HTMLMediaElement', v7/*class(MediaElementImpl)*/],
    ['Element', v9/*class(ElementImpl)*/],
    ['Entry', 'Entry|FileEntry|DirectoryEntry|FileEntry|DirectoryEntry'],
    ['EntrySync', 'EntrySync|FileEntrySync|DirectoryEntrySync|FileEntrySync|DirectoryEntrySync'],
    ['Event', 'Event|WebGLContextEvent|UIEvent|TouchEvent|TextEvent|SVGZoomEvent|MouseEvent|WheelEvent|WheelEvent|KeyboardEvent|CompositionEvent|TouchEvent|TextEvent|SVGZoomEvent|MouseEvent|WheelEvent|WheelEvent|KeyboardEvent|CompositionEvent|WebKitTransitionEvent|TrackEvent|StorageEvent|SpeechRecognitionEvent|SpeechRecognitionError|SpeechInputEvent|ProgressEvent|XMLHttpRequestProgressEvent|XMLHttpRequestProgressEvent|PopStateEvent|PageTransitionEvent|OverflowEvent|OfflineAudioCompletionEvent|MutationEvent|MessageEvent|MediaStreamTrackEvent|MediaStreamEvent|MediaKeyEvent|IDBVersionChangeEvent|IDBUpgradeNeededEvent|HashChangeEvent|ErrorEvent|DeviceOrientationEvent|DeviceMotionEvent|CustomEvent|CloseEvent|BeforeLoadEvent|AudioProcessingEvent|WebKitAnimationEvent|WebGLContextEvent|UIEvent|TouchEvent|TextEvent|SVGZoomEvent|MouseEvent|WheelEvent|WheelEvent|KeyboardEvent|CompositionEvent|TouchEvent|TextEvent|SVGZoomEvent|MouseEvent|WheelEvent|WheelEvent|KeyboardEvent|CompositionEvent|WebKitTransitionEvent|TrackEvent|StorageEvent|SpeechRecognitionEvent|SpeechRecognitionError|SpeechInputEvent|ProgressEvent|XMLHttpRequestProgressEvent|XMLHttpRequestProgressEvent|PopStateEvent|PageTransitionEvent|OverflowEvent|OfflineAudioCompletionEvent|MutationEvent|MessageEvent|MediaStreamTrackEvent|MediaStreamEvent|MediaKeyEvent|IDBVersionChangeEvent|IDBUpgradeNeededEvent|HashChangeEvent|ErrorEvent|DeviceOrientationEvent|DeviceMotionEvent|CustomEvent|CloseEvent|BeforeLoadEvent|AudioProcessingEvent|WebKitAnimationEvent'],
    ['Node', v14/*class(NodeImpl)*/],
    ['MediaStream', v15/*class(MediaStreamImpl)*/],
    ['IDBRequest', v16/*class(IDBRequestImpl)*/],
    ['EventTarget', [v13/*class(WorkerContextImpl)*/,v14/*class(NodeImpl)*/,v15/*class(MediaStreamImpl)*/,v16/*class(IDBRequestImpl)*/,v17/*class(AbstractWorkerImpl)*/,v13/*class(WorkerContextImpl)*/,v14/*class(NodeImpl)*/,v15/*class(MediaStreamImpl)*/,v16/*class(IDBRequestImpl)*/,v17/*class(AbstractWorkerImpl)*/,'EventTarget|DOMWindow|WebSocket|WebKitNamedFlow|TextTrackList|TextTrackCue|TextTrack|SpeechRecognition|SourceBufferList|SVGElementInstance|RTCPeerConnection|Performance|PeerConnection00|Notification|MessagePort|MediaStreamTrackList|MediaStreamTrack|MediaSource|MediaController|IDBTransaction|IDBDatabase|XMLHttpRequestUpload|XMLHttpRequest|FileWriter|FileReader|EventSource|DOMApplicationCache|BatteryManager|AudioContext|DOMWindow|WebSocket|WebKitNamedFlow|TextTrackList|TextTrackCue|TextTrack|SpeechRecognition|SourceBufferList|SVGElementInstance|RTCPeerConnection|Performance|PeerConnection00|Notification|MessagePort|MediaStreamTrackList|MediaStreamTrack|MediaSource|MediaController|IDBTransaction|IDBDatabase|XMLHttpRequestUpload|XMLHttpRequest|FileWriter|FileReader|EventSource|DOMApplicationCache|BatteryManager|AudioContext'].join('|')],
    ['HTMLCollection', 'HTMLCollection|HTMLOptionsCollection|HTMLOptionsCollection'],
    ['IDBCursor', 'IDBCursor|IDBCursorWithValue|IDBCursorWithValue'],
    ['NodeList', 'NodeList|RadioNodeList|RadioNodeList']];
$.dynamicSetMetadata(table);
})();

if (typeof document != 'undefined' && document.readyState != 'complete') {
  document.addEventListener('readystatechange', function () {
    if (document.readyState == 'complete') {
      $.main();
    }
  }, false);
} else {
  $.main();
}
function init() {
Isolate.$isolateProperties = {};
Isolate.$defineClass = function(cls, fields, prototype) {
  var generateGetterSetter = function(field, prototype) {
  var len = field.length;
  var lastChar = field[len - 1];
  var needsGetter = lastChar == '?' || lastChar == '=';
  var needsSetter = lastChar == '!' || lastChar == '=';
  if (needsGetter || needsSetter) field = field.substring(0, len - 1);
  if (needsGetter) {
    var getterString = "return this." + field + ";";
    prototype["get$" + field] = new Function(getterString);
  }
  if (needsSetter) {
    var setterString = "this." + field + " = v;";
    prototype["set$" + field] = new Function("v", setterString);
  }
  return field;
};
  var constructor;
  if (typeof fields == 'function') {
    constructor = fields;
  } else {
    var str = "function " + cls + "(";
    var body = "";
    for (var i = 0; i < fields.length; i++) {
      if (i != 0) str += ", ";
      var field = fields[i];
      field = generateGetterSetter(field, prototype);
      str += field;
      body += "this." + field + " = " + field + ";\n";
    }
    str += ") {" + body + "}\n";
    str += "return " + cls + ";";
    constructor = new Function(str)();
  }
  constructor.prototype = prototype;
  return constructor;
};
var supportsProto = false;
var tmp = Isolate.$defineClass('c', ['f?'], {}).prototype;
if (tmp.__proto__) {
  tmp.__proto__ = {};
  if (typeof tmp.get$f !== "undefined") supportsProto = true;
}
Isolate.$pendingClasses = {};
Isolate.$finishClasses = function(collectedClasses) {
  for (var cls in collectedClasses) {
    if (Object.prototype.hasOwnProperty.call(collectedClasses, cls)) {
      var desc = collectedClasses[cls];
      Isolate.$isolateProperties[cls] = Isolate.$defineClass(cls, desc[''], desc);
      if (desc['super'] !== "") Isolate.$pendingClasses[cls] = desc['super'];
    }
  }
  var pendingClasses = Isolate.$pendingClasses;
  Isolate.$pendingClasses = {};
  var finishedClasses = {};
  function finishClass(cls) {
    if (finishedClasses[cls]) return;
    finishedClasses[cls] = true;
    var superclass = pendingClasses[cls];
    if (!superclass) return;
    finishClass(superclass);
    var constructor = Isolate.$isolateProperties[cls];
    var superConstructor = Isolate.$isolateProperties[superclass];
    if (!(typeof(superConstructor) == "undefined")) {
      var prototype = constructor.prototype;
      if (supportsProto) {
        prototype.__proto__ = superConstructor.prototype;
        prototype.constructor = constructor;
      } else {
        function tmp() {};
        tmp.prototype = superConstructor.prototype;
        var newPrototype = new tmp();
        constructor.prototype = newPrototype;
        newPrototype.constructor = constructor;
          var hasOwnProperty = Object.prototype.hasOwnProperty;
        for (var member in prototype) {
          if (member == '' || member == 'super') continue;
          if (hasOwnProperty.call(prototype, member)) {
            newPrototype[member] = prototype[member];
          }
        }
      }
    }
  }
  for (var cls in pendingClasses) finishClass(cls);
};
Isolate.$finishIsolateConstructor = function(oldIsolate) {
  var isolateProperties = oldIsolate.$isolateProperties;
  var isolatePrototype = oldIsolate.prototype;
  var str = "{\n";
  str += "var properties = Isolate.$isolateProperties;\n";
  for (var staticName in isolateProperties) {
    if (Object.prototype.hasOwnProperty.call(isolateProperties, staticName)) {
      str += "this." + staticName + "= properties." + staticName + ";\n";
    }
  }
  str += "}\n";
  var newIsolate = new Function(str);
  newIsolate.prototype = isolatePrototype;
  isolatePrototype.constructor = newIsolate;
  newIsolate.$isolateProperties = isolateProperties;
  return newIsolate;
};
}
