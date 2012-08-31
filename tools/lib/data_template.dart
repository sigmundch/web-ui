// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Support classes and functions used by the code generated from a template. */
#library('data_template');

#import('dart:html');
#import('../../watcher.dart');

safeHTML(v) {
  if (v is String) {
    // TODO(terry): Escape the string here.
    return v;
  } else {
    // Not a String just return the raw value.
    return v;
  }
}

// Template/data binding system.
interface BaseController {
  /**
   *  User must implement the model property.  Instead of returning object
   *  return the application's real model type.
   */
  get model();
}


wrap1(f) => (e) { f(e); dispatch(); };

typedef Element BoundElement(Element e0);

// TODO(terry): Need to handle child elements with {{modelName}}.
// TODO(terry): Need to handle template iterator.
// TODO(terry): Need to handle template ifs.
// TODO(terry): Assumption for 2-way binding the attributes/DOM properties are
//              automatically hooked to the particular event of that HTML's tag
//              that binds to that property.
/**
 * Each HTML element with attributes or text nodes that contains an expression
 * of the form {{expr}} has a BoundElementEntry.  Each time an expression
 * changes the attributes/text nodes are re-computed and changed to that
 * rendered element.
 */
class BoundElementEntry {
  Element _elemRendered;
  BoundElement _boundElem;

  BoundElementEntry(BoundElement elem)
      : _boundElem = elem, _elemRendered = null;

  /**
   * Create the elements with template expression or update the just the attrs
   * or text nodes associated with a bound expression.  If _elemRendered is null
   * then this bound element is being rendered for the first time.  If
   * _elemRendered is not null then this element will replace attributes and or
   * text nodes.
   */
  Element createOrUpdate() {
    _elemRendered = _boundElem(_elemRendered);
    return _elemRendered;
  }
}

/**
 * The generated code associated with each template is derived from this
 * abstract base class.
 */
class Template {
  /** Controller for the application. */
  var _controller;

  /** Rendered parent HTML element that this template is child element. */
  Element _parent;

  /** Elements in the templates that are data bound; expression {{nnnn}} */
  List<BoundElementEntry> _boundElems;

  Template(var ctrl, Element parent)
      : _controller = ctrl,
        _parent = parent,
        _boundElems = <BoundElementEntry>[];

  get model() => _controller.model;
  Element get parent() => _parent;
  List<BoundElementEntry> get boundElements() => _boundElems;


  abstract void render();

  /**
   * [index] of the bound element to run and the last element created for this
   * bound element; createOrUpdate invoke the bound element and the returned
   * element either changed or created (first time rendered).  This is where
   * the fine-grain updates are done (calling the bound element function).
   */
  Element fineGrainUpdate(int index) {
    return _boundElems[index].createOrUpdate();
  }

  /**
   * Renders fine grain update first-time through @ first render time.  Then
   * setup watch for a model change to cause just the template parts that are
   * regenerated when that model value changes.
   */
  Element renderSetupFineGrainUpdates(target, int index) {
    // TODO(terry): Save WatcherDisposer returned by watch to collect watchers.
    watch(target, (_) { fineGrainUpdate(index); });
    return fineGrainUpdate(index);
  }
}

/**
 * The application object manages the rendering of the UI, binding the
 * controller to the application and rendering the template.
 */
class Application {
  /** DOM node to generate template. */
  Element root;

  /** Controller for this application. */
  BaseController _controller;

  // TODO(terry): Need to support more than one template.
  /** Template associated with this application. */
  var _template;

  Application(BaseController controller): _controller = controller;

  BaseController get controller() => _controller;

  abstract Template createTemplate(Element templateParent);

  display() {
    if (_template == null) {
      _template = createTemplate(root);
    }
    _template.render();

    return root;
  }
}
