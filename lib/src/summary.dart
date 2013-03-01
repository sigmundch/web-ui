// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** 
 * Summary information for components and libraries.
 *
 * These classes are used for modular compilation. Summaries are a subset of the
 * information collected by Info objects (see `info.dart`). When we are
 * compiling a single file, the information extracted from that file is stored
 * as info objects, but any information that is needed from other files (like
 * imported components) is stored as a summary.
 */
library web_ui.src.summary;

import 'file_system/path.dart';
import 'package:source_maps/span.dart' show Span;

class LibrarySummary {
  final Path inputPath;
  final String outputFilename;
  LibrarySummary(this.inputPath, this.outputFilename);
}

/** Information about a web component definition. */
class ComponentSummary extends LibrarySummary {
  /** The component tag name, defined with the `name` attribute on `element`. */
  final String tagName;

  /**
   * The tag name that this component extends, defined with the `extends`
   * attribute on `element`.
   */
  final String extendsTag;

  /**
   * The Dart class containing the component's behavior, derived from tagName or
   * defined in the `constructor` attribute on `element`.
   */
  final String className;

  final ComponentSummary extendsComponent;

  /**
   * True if [tagName] was defined by more than one component. If this happened
   * we will skip over the component.
   */
  bool hasConflict;

  /** Original span where this component is declared. */
  final Span sourceSpan;

  ComponentSummary(Path inputPath, String outputFilename,
      this.tagName, this.extendsTag, this.className, this.extendsComponent,
      this.sourceSpan, [this.hasConflict = false])
      : super(inputPath, outputFilename);

  /**
   * Gets the HTML tag extended by the base of the component hierarchy.
   * Equivalent to [extendsTag] if this inherits directly from an HTML element,
   * in other words, if [extendsComponent] is null.
   */
  String get baseExtendsTag =>
      extendsComponent == null ? extendsTag : extendsComponent.baseExtendsTag;
}
