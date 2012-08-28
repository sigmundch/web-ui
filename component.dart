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
#import("package:webcomponents/webcomponents.dart");
#import("package:webcomponents/watcher.dart");

typedef void Action();

// TODO(jmesserly): I don't like having this scope class, but we can't fake a
// Dart object declaring this variable due to dartbug.com/4424.
class ComponentScope {
  final parent;
  final Map variables;

  ComponentScope(parent, this.variables)
      : parent = parent is ComponentScope ? parent.dynamic.parent : parent {

    if (parent is ComponentScope) {
      // add variables from parent unless it's shadowed.
      ComponentScope scope = parent;
      scope.forEach((key, value) {
        if (!variables.contains(key)) {
          variables[key] = value;
        }
      });
    }
  }
}

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
  int componentId;

  /** Name for the kind of component, currently only used for debugging. */
  String name;

  static int _id = 0;
  Element _element;
  // TODO(jacobr): specifying shadow root like this is wrong as subclasses
  // should always have different shadow roots than their parent classes.
  ShadowRoot _root;

  List<Action> _insertActions;
  List<Action> _removeActions;

  // TODO(jmesserly): you can also compute this from the DOM by walking the
  // parent chain.
  bool _inDocument = false;

  MutationObserver _observer;

  /**
   * The component that we use to lookup bindings. Generally this is the
   * component corresponding to the lexically enclosing `<element>` tag. For the
   * application this is the controller class.
   */
  var declaringScope;

  Component(this.name, this._element)
      : componentId = _id++,
        // TODO(jmesserly): initialize lazily
        _insertActions = [],
        _removeActions = [] {
  }

  // TODO(jmesserly): rename these shadowRoot and host?
  Element get element() => _element;
  ShadowRoot get root() => _root;

  // TODO(sigmund): delete print statements or use logging library.
  void created(ShadowRoot root) {
    _root = root;
    print('$name $componentId-created');
  }

  void inserted() {
    print('$name $componentId-inserted');

    _bindFields();

    // TODO(jmesserly): is this too late to bind data? If we bind it any
    // earlier, we won't have mutation observer set up, and might miss changes.
    if (_root != null) {
      for (var child in _root.elements) {
        _bindDataRecursive(child);
      }
    }

    _observer = new MutationObserver((mutations, observer) {
      for (var mutation in mutations) {
        // TODO(samhop): remove this test if it turns out that it always passes
        if (mutation.type == 'childList') {
          for (var node in mutation.addedNodes) {
            if (node is Element) _bindData(node);
          }
        }
      }
    });
    if (_root != null) {
      _observer.observe(_root, childList: true, subtree: true);
    }

    for (var action in _insertActions) action();
    _inDocument = true;
  }

  void removed() {
    print('$name $id-removed');

    if (_observer != null) {
      _observer.disconnect();
    }

    for (var action in _removeActions) action();
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

  void _bindDataRecursive(Element node) {
    if (manager[node] != null) return;

    // TODO(jmesserly): this full tree walk is problematic
    for (var child in node.elements) _bindDataRecursive(child);

    _bindData(node);
  }

  void _bindData(Element node) {
    // TODO(jmesserly): all of these guys share the same basic structure.
    _bindEvents(node);
    _bindAttributes(node);
    _bindText(node);
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

      var self = reflect(this);
      var caller = (e) {
        // TODO(jmesserly): shouldn't we pass in event args somehow?
        // var args = [reflect(e)];
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

      WatcherDisposer disposer = null;
      lifecycleAction(() {
        // TODO(jmesserly): what about two way binding? Mutation observers?
        disposer = bind(() => mirrorGet(this, value).reflectee, (e) {
          if (key == "checked") {
            node.dynamic.checked = e.newValue;
          } else {
            node.attributes[key] = e.newValue;
          }
        });
      }, () => disposer());
    }

    node.attributes.forEach(bindAttr);
    node.dataAttributes.forEach(bindAttr);
  }

  void _bindText(Element node) {
    // TODO(jmesserly): support text nodes mixed in with elements
    if (node.elements.length > 0) return;

    var re = const RegExp('{{(.*)}}');
    // TODO(jmesserly): support multiple expressions
    var pattern = node.text;
    var match = re.firstMatch(pattern);
    if (match == null) return;

    var expr = match[1];

    WatcherDisposer disposer = null;
    lifecycleAction(() {
      disposer = bind(() => mirrorGet(this, expr).reflectee, (e) {
        node.text = pattern.replaceFirst(re, '${e.newValue}');
      });
    }, () => disposer());
  }

  void _bindFields() {
    element.dataAttributes.forEach((key, value) {
      if (key.startsWith('bind-')) {
        String name = key.substring('bind-'.length);

        var self = reflect(this);
        self.setField(name, mirrorGet(declaringScope, value));

        // TODO(jmesserly): watcher is overkill for the common case of a loop
        // variable.
        WatcherDisposer disposer = null;
        lifecycleAction(() {
          disposer = watch(() => mirrorGet(declaringScope, value), (e) {
            self.setField(name, e.newValue);
          });
        }, () => disposer());
      }
    });
  }

  // TODO(jmesserly): public so IfComponent can use it
  InstanceMirror mirrorGet(scope, String identifier) {
    var names = identifier.split('.');

    // TODO(jmesserly): search order is wrong. Loop vars should be first
    // (they're the nearest enclosing scope), then controller class,
    // then global, then controller superclasses (Dart is lexical before
    // inherited scope).
    var mirror = currentMirrorSystem();

    // Is it a loop variable?
    var item = null;
    if (scope is ComponentScope) {
      item = scope.dynamic.variables[names[0]];
      if (item != null) {
        scope = item;
        names.removeRange(0, 1);
      }
    }

    // Is it declared at the top level?
    if (item == null) {
      var global = _mirrorGetGlobal(names[0]);
      if (global != null) {
        scope = global.reflectee;
        names.removeRange(0, 1);
      }
    }

    var self = reflect(scope);
    for (var name in names) {
      self = self.getField(name).value;
    }
    return self;
  }

  static ObjectMirror _mirrorGetGlobal(String name) {
    // TODO(jmesserly): this isn't the right way to search for globals... we
    // need to know what Dart library we're starting the search from, so we
    // handle library prefixes and imports properly.
    // In general the template polyfill needs a scoping mechanism.
    var mirror = currentMirrorSystem();
    for (var lib in mirror.libraries.getValues()) {
      var member = lib.members[name];
      if (member != null) {
        return lib.getField(name).value;
      }
    }
    return null;
  }

  // This is a temporary hack until Dart supports subclassing elements.
  // TODO(jacobr): use mirrors instead.

  NodeList get nodes() => _element.nodes;

  void set nodes(Collection<Node> value) { _element.nodes = value; }

  /**
   * Replaces this node with another node.
   */
  Node replaceWith(Node otherNode) { _element.replaceWith(otherNode); }

  /**
   * Removes this node from the DOM.
   */
  Node remove() { _element.remove(); }
  Node get nextNode() => _element.nextNode;

  Document get document() => _element.document;

  Node get previousNode() => _element.previousNode;

  String get text() => _element.text;

  void set text(String v) { _element.text = v; }

  bool contains(Node other) => _element.contains(other);

  bool hasChildNodes() => _element.hasChildNodes();

  Node insertBefore(Node newChild, Node refChild) =>
    _element.insertBefore(newChild, refChild);

  AttributeMap get attributes() => _element.attributes;
  void set attributes(Map<String, String> value) {
    _element.attributes = value;
  }

  ElementList get elements() => _element.elements;

  void set elements(Collection<Element> value) {
    _element.elements = value;
  }

  Set<String> get classes() => _element.classes;

  void set classes(Collection<String> value) {
    _element.classes = value;
  }

  AttributeMap get dataAttributes() => _element.dataAttributes;
  void set dataAttributes(Map<String, String> value) {
    _element.dataAttributes = value;
  }

  Future<ElementRect> get rect() => r.rect;

  Future<CSSStyleDeclaration> get computedStyle() => r.computedStyle;

  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement)
    => r.getComputedStyle(pseudoElement);

  Element clone(bool deep) => _element.clone(deep);

  Element get parent() => _element.parent;

  ElementEvents get on() => _element.on;

  String get contentEditable() => _element.contentEditable;

  String get dir() => _element.dir;

  bool get draggable() => _element.draggable;

  bool get hidden() => _element.hidden;

  String get id() => _element.id;

  String get innerHTML() => _element.innerHTML;

  bool get isContentEditable() => _element.isContentEditable;

  String get lang() => _element.lang;

  String get outerHTML() => _element.outerHTML;

  bool get spellcheck() => _element.spellcheck;

  int get tabIndex() => _element.tabIndex;

  String get title() => _element.title;

  bool get translate() => _element.translate;

  String get webkitdropzone() => _element.webkitdropzone;

  void click() { _element.click(); }

  Element insertAdjacentElement(String where, Element element) =>
    _element.insertAdjacentElement(where, element);

  void insertAdjacentHTML(String where, String html) {
    _element.insertAdjacentHTML(where, html);
  }

  void insertAdjacentText(String where, String text) {
    _element.insertAdjacentText(where, text);
  }

  Map<String, String> get dataset() => _element.dataset;

  Element get nextElementSibling() => _element.nextElementSibling;

  Element get offsetParent() => _element.offsetParent;

  Element get previousElementSibling() => _element.previousElementSibling;

  CSSStyleDeclaration get style() => _element.style;

  String get tagName() => _element.tagName;
  String set tagName(String v) => _element.tagName = v;

  String get webkitRegionOverflow() => _element.webkitRegionOverflow;

  void blur() { _element.blur(); }

  void focus() { _element.focus(); }

  void scrollByLines(int lines) {
    _element.scrollByLines(lines);
  }

  void scrollByPages(int pages) {
    _element.scrollByPages(pages);
  }

  void scrollIntoView([bool centerIfNeeded]) {
    if (centerIfNeeded == null) {
      _element.scrollIntoView();
    } else {
      _element.scrollIntoView(centerIfNeeded);
    }
  }

  bool matchesSelector(String selectors) => _element.matchesSelector(selectors);

  void webkitRequestFullScreen(int flags) { _element.webkitRequestFullScreen(flags); }

  void webkitRequestFullscreen() { _element.webkitRequestFullscreen(); }

  void webkitRequestPointerLock() { _element.webkitRequestPointerLock(); }

  Element query(String selectors) => _element.query(selectors);

  List<Element> queryAll(String selectors) => _element.queryAll(selectors);
}
