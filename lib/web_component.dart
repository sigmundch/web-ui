// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Declares the [WebComponent] base class (eventually: mixin). */
library web_component;
import 'dart:html';

/**
 * The base class for all Dart web components. In addition to the [Element]
 * interface, it also provides lifecycle methods:
 * - [created]
 * - [inserted]
 * - [attributeChanged]
 * - [removed]
 */
abstract class WebComponent implements Element {
  /** The web component element wrapped by this class. */
  final Element _element;

  static bool _hasShadowRoot = true;

  /**
   * Temporary constructor until components extend [Element]. Attaches this
   * component to the provided [element]. The element must not already have a
   * component associated with it.
   */
  WebComponent.forElement(Element element) : _element = element {
    if (element == null || (_element as Dynamic).xtag != null) {
      throw new IllegalArgumentException(
          'element must be provided and not have its xtag property set');
    }
    (_element as Dynamic).xtag = this;
  }

  /**
   * Creates the [ShadowRoot] backing this component. This is an implementation
   * helper and should not need to be called from your code.
   */
  createShadowRoot() {
    var shadowRoot;
    if (_hasShadowRoot) {
      try {
        shadowRoot = new ShadowRoot(_element);
        // TODO(jmesserly): what's up with this flag? Why are we setting it?
        shadowRoot.resetStyleInheritance = false;
      } catch (e) {
        // TODO(jmesserly): need a way to detect this that won't throw an
        // exception. Throw+catch creates a bad user experience in the editor.
        _hasShadowRoot = false;
      }
    }

    if (!_hasShadowRoot) {
      shadowRoot = new Element.html('<div class="shadowroot"></div>');
      nodes.add(shadowRoot);
    }

    return shadowRoot;
  }

  /**
   * Invoked when this component gets created.
   * Note that [root] will be a [ShadowRoot] if the browser supports Shadow DOM.
   */
  void created() {}

  /** Invoked when this component gets inserted in the DOM tree. */
  void inserted() {}

  /** Invoked when this component is removed from the DOM tree. */
  void removed() {}

  // TODO(jmesserly): how do we implement this efficiently?
  // See https://github.com/dart-lang/dart-web-components/issues/37
  /** Invoked when any attribute of the component is modified. */
  void attributeChanged(
      String name, String oldValue, String newValue) {}


  // TODO(jmesserly): this forwarding is temporary until Dart supports
  // subclassing Elements.

  NodeList get nodes => _element.nodes;

  set nodes(Collection<Node> value) { _element.nodes = value; }

  /**
   * Replaces this node with another node.
   */
  Node replaceWith(Node otherNode) { _element.replaceWith(otherNode); }

  /**
   * Removes this node from the DOM.
   */
  Node remove() => _element.remove();

  Node get nextNode => _element.nextNode;

  Document get document => _element.document;

  Node get previousNode => _element.previousNode;

  String get text => _element.text;

  set text(String v) { _element.text = v; }

  bool contains(Node other) => _element.contains(other);

  bool hasChildNodes() => _element.hasChildNodes();

  Node insertBefore(Node newChild, Node refChild) =>
    _element.insertBefore(newChild, refChild);

  AttributeMap get attributes => _element.attributes;
  set attributes(Map<String, String> value) {
    _element.attributes = value;
  }

  List<Element> get elements => _element.elements;

  set elements(Collection<Element> value) {
    _element.elements = value;
  }

  Set<String> get classes => _element.classes;

  set classes(Collection<String> value) {
    _element.classes = value;
  }

  AttributeMap get dataAttributes => _element.dataAttributes;
  set dataAttributes(Map<String, String> value) {
    _element.dataAttributes = value;
  }

  Future<ElementRect> get rect => _element.rect;

  Future<CSSStyleDeclaration> get computedStyle => _element.computedStyle;

  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement)
    => _element.getComputedStyle(pseudoElement);

  Element clone(bool deep) => _element.clone(deep);

  Element get parent => _element.parent;

  ElementEvents get on => _element.on;

  String get contentEditable => _element.contentEditable;

  String get dir => _element.dir;

  bool get draggable => _element.draggable;

  bool get hidden => _element.hidden;

  String get id => _element.id;

  String get innerHTML => _element.innerHTML;

  bool get isContentEditable => _element.isContentEditable;

  String get lang => _element.lang;

  String get outerHTML => _element.outerHTML;

  bool get spellcheck => _element.spellcheck;

  int get tabIndex => _element.tabIndex;

  String get title => _element.title;

  bool get translate => _element.translate;

  String get webkitdropzone => _element.webkitdropzone;

  void click() { _element.click(); }

  Element insertAdjacentElement(String where, Element element) =>
    _element.insertAdjacentElement(where, element);

  void insertAdjacentHTML(String where, String html) {
    _element.insertAdjacentHTML(where, html);
  }

  void insertAdjacentText(String where, String text) {
    _element.insertAdjacentText(where, text);
  }

  Map<String, String> get dataset => _element.dataset;

  Element get nextElementSibling => _element.nextElementSibling;

  Element get offsetParent => _element.offsetParent;

  Element get previousElementSibling => _element.previousElementSibling;

  CSSStyleDeclaration get style => _element.style;

  String get tagName => _element.tagName;

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

  void webkitRequestFullScreen(int flags) {
    _element.webkitRequestFullScreen(flags);
  }

  void webkitRequestFullscreen() { _element.webkitRequestFullscreen(); }

  void webkitRequestPointerLock() { _element.webkitRequestPointerLock(); }

  Element query(String selectors) => _element.query(selectors);

  List<Element> queryAll(String selectors) => _element.queryAll(selectors);
}
