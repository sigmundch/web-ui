// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('analysis');

#import('dart:coreimpl');
#import('package:html5lib/html5parser.dart');
#import('package:html5lib/tokenizer.dart');
#import('package:html5lib/treebuilders/simpletree.dart');
#import('package:web_components/tools/lib/file_system.dart');
#import('package:web_components/tools/lib/world.dart');
#import('analyzer.dart', prefix: 'analyzer');
#import('code_printer.dart');
#import('codegen.dart');
#import('codegen_application.dart');
#import('codegen_component.dart');
#import('compilation_unit.dart');
#import('processor.dart');
#import('template.dart');
#import('utils.dart');

// TODO(jmesserly): move these things into html5lib's public api
// This is for voidElements:
#import('package:html5lib/lib/constants.dart', prefix: 'html5_constants');
// This is for htmlEscapeMinimal:
#import('package:html5lib/lib/utils.dart', prefix: 'html5_utils');


// TODO(terry): Too many classes in this file need to break up walking, analysis
//              and codegen to different files (started but needs to finished).
// TODO(terry): Add obfuscation mapping file.
Document parseHtml(String template, String sourcePath) {
  var parser = new HTMLParser();
  var document = parser.parse(new HTMLTokenizer(template));

  // Note: errors aren't fatal in HTML (unless strict mode is on).
  // So just print them as warnings.
  for (var e in parser.errors) {
    world.warning('$sourcePath line ${e.line}:${e.column}: ${e.message}');
  }
  return document;
}

/**
 * Walk the tree produced by the parser looking for templates, expressions, etc.
 * as a prelude to emitting the code for the template.
 */
class Compile {
  final FileSystem filesystem;
  final String baseDir;
  final ProcessFiles components;

  /** Used by template tool to open a file. */
  Compile(this.filesystem, String filename, [this.baseDir = ""])
      : components = new ProcessFiles() {
    components.add(filename, isWebComponent: false);
    _compile();
  }

  /**
   * All compiler work start here driven by the files processor.
   */
  void _compile() {
    var process;
    while ((process = components.nextProcess()) != ProcessFile.NULL_PROCESS) {
      if (!process.isProcessRunning) {
        // No process is running; so this is the next process to run.
        process.toProcessRunning();

        switch (process.phase) {
          case ProcessFile.PARSING:
            // Parse the template.
            var source = filesystem.readAll("$baseDir/${process.cu.filename}");

            final parsedElapsed = time(() {
              process.cu.document = parseHtml(source, process.cu.filename);
            });
            if (options.showInfo) {
              printStats("Parsed", parsedElapsed, process.cu.filename);
            }
            if (options.dumpTree) {
              print("\n\n Dump Tree ${process.cu.filename}:\n\n");
              print(process.cu.document.outerHTML);
              print("\n=========== End of AST ===========\n\n");
            }
            break;
          case ProcessFile.WALKING:
            final duration = time(() {
              process.cu.info = analyzer.analyze(process.cu.document);
            });
            // Walk the tree.
            final walkedElapsed = time(() {
              _walkTree(process.cu.document, process.cu.elemCG);
            });
            if (options.showInfo) {
              printStats("Analyzed", duration, process.cu.filename);
              printStats("Walked", walkedElapsed, process.cu.filename);
            }
            break;
          case ProcessFile.ANALYZING:
            // Find next process to analyze.

            // TODO(terry): All analysis should be done here.  Today analysis
            //              is done in both ElemCG and CBBlock; these analysis
            //              parts should be moved into the Analyze class.  The
            //              tree walker portion should be a separate class that
            //              just does tree walking and produce the object graph
            //              that is intermingled with CGBlock, ElemCG and the
            //              CGStatement classes.

            // TODO(terry): The analysis phase not implemented.

            if (options.showInfo) {
              printStats("Analyzed", 0, process.cu.filename);
            }
            break;
          case ProcessFile.EMITTING:
            // Spit out the code for this file processed.
            final codegenElapsed = time(() {
              process.cu.code = _emitter(process);
              String filename = process.cu.filename;
              String html = _emitterHTML(process);
              process.cu.html =
                  "<!-- Generated Web Component from HTML template ${filename}."
                  "  DO NOT EDIT. -->\n"
                  "$html";
            });
            if (options.showInfo) {
              printStats("Codegen", codegenElapsed, process.cu.filename);
            }
            break;
          default:
            world.error("Unexpected process $process");
            return;
        }

        // Signal this process has completed running for this phase.
        process.toProcessDone();
      }
    }
  }

  /** Walk the HTML tree of the template file. */
  void _walkTree(Document doc, ElemCG ecg) {
    if (!ecg.pushBlock()) {
      world.error("Error at ${doc.nodes}");
    }

    // Start from the HTML node.
    var start = doc.query('html');

    bool firstTime = true;
    for (var child in start.nodes) {
      if (child is Text) {
        if (!firstTime) {
          ecg.closeStatement();
        }

        // Skip any empty text nodes; no need to pollute the pretty-printed
        // HTML.
        // TODO(terry): Need to add {space}, {/r}, etc. like Soy.
        String textNodeValue = child.value.trim();
        if (textNodeValue.length > 0) {
          CGStatement stmt = ecg.pushStatement(child, "frag");
        }
        continue;
      }

      ecg.emitConstructHtml(child, "", "frag");
      firstTime = false;
    }
  }

  /** Emit the Dart code. */
  String _emitter(ProcessFile process) {
    CompilationUnit cu = process.cu;
    String libraryName = cu.filename.replaceAll('.', '_');

    if (cu.isWebComponent) {
      return CodegenComponent.generate(libraryName, cu.filename, cu.elemCG);
    } else {
      return CodegenApplication.generate(libraryName, cu.filename, cu.elemCG);
    }
  }

  String _emitterHTML(ProcessFile process) {
    // TODO(terry): Need special emitter for main vs web component.

    // TODO(jmesserly): not sure about removing script nodes like this
    // But we need to do this for web components to work.
    var scriptTags = process.cu.document.queryAll('script');
    for (var tag in scriptTags) {
      // TODO(jmesserly): use tag.remove() once it's supported.
      tag.parent.$dom_removeChild(tag);
    }

    return process.cu.document.outerHTML;
  }

  /**
   * Helper function to iterate throw all compilation units used by the tool
   * to write out the results of the compile.
   */
  void forEach(void f(CompilationUnit cu)) {
    components.forEach((ProcessFile pf) {
      f(pf.cu);
    });
  }
}


/**
 * CodeGen block used for a set of statements to be emited wrapped around a
 * template control that implies a block (e.g., iterate, with, etc.).  The
 * statements (HTML) within that block are scoped to a CGBlock.
 */
class CGBlock {
  final List<CGStatement> _stmts;

  /** Local variable index (e.g., e0, e1, etc.). */
  int _localIndex;

  final analyzer.TemplateInfo template;
  final Element templateElement;
  final ProcessFiles processor;

  CGBlock(ProcessFiles processor, [Element templateElement])
      : processor = processor,
        templateElement = templateElement,
        template = (templateElement != null ?
            processor.current.cu.info[templateElement] : null),
        _stmts = <CGStatement>[],
        _localIndex = 0;

  bool get hasStatements => !_stmts.isEmpty();
  bool get isConstructor => template == null;
  bool get isTemplate => template != null;

  /**
   * Each statement (HTML) encountered is remembered with either/both variable
   * name of parent and local name to associate with this element when the DOM
   * constructed.
   */
  CGStatement push(elem, parentName, [bool exact = false]) {
    // TODO(jmesserly): fix this int|String union type.
    var varName;
    analyzer.ElementInfo info = processor.current.cu.info[elem];
    if (info != null) varName = info.idAsIdentifier;

    if (varName == null) {
      varName = _localIndex++;
    }

    var s = new CGStatement(elem, info, parentName, varName, exact);
    _stmts.add(s);
    return s;
  }

  void add(String value) {
    if (_stmts.last() != null) {
      _stmts.last().add(value);
    }
  }

  CGStatement get last => _stmts.length > 0 ? _stmts.last() : null;

  /**
   * Returns mixed list of elements marked with the var attribute.  If the
   * element is inside of a #each the name exposed is:
   *
   *      List varName;
   *
   * otherwise it's:
   *
   *      var varName;
   *
   * TODO(terry): For scalars var varName should be Element tag type e.g.,
   *
   *                   DivElement varName;
   */
  String get globalDeclarations {
    StringBuffer buff = new StringBuffer();
    for (CGStatement stmt in _stmts) {
      buff.add(stmt.globalDeclaration());
    }

    return buff.toString();
  }

  int get boundElementCount {
    int count = 0;
    if (isTemplate) {
      for (var stmt in _stmts) {
        if (stmt.hasDataBinding) {
          count++;
        }
      }
    }
    return count;
  }

  // TODO(terry): Need to update this when iterate is driven from the
  //             <template iterate='name in names'>.  Nested iterates are
  //             a List<List<Elem>>.
  /**
   * List of statement constructors for each var inside a #each.
   *
   *    ${#each products}
   *      <div var=myVar>...</div>
   *    ${/each}
   *
   * returns:
   *
   *    myVar = [];
   */
  String get globalInitializers {
    StringBuffer buff = new StringBuffer();
    for (CGStatement stmt in _stmts) {
      buff.add(stmt.globalInitializers());
    }

    return buff.toString();
  }

  String get codeBody {
    StringBuffer buff = new StringBuffer();

    // If statement is a bound element, has {{ }}, then boundElemIdx will match
    // the BoundElementEntry index associated with this element's statement.
    int boundElemIdx = 0;
    for (CGStatement stmt in _stmts) {
      buff.add(stmt.emitStatement(boundElemIdx));
      if (stmt.hasDataBinding) {
        boundElemIdx++;
      }
    }

    return buff.toString();
  }

  static String genBoundElementsCommentBlock = @"""


  // ==================================================================
  // Tags that contains a template expression {{ nnnn }}.
  // ==================================================================""";

  String templatesCodeBody() {
    StringBuffer buff = new StringBuffer();

    buff.add(genBoundElementsCommentBlock);

    int boundElemIdx = 0;   // Index if statement is a bound elem has a {{ }}.
    for (CGStatement stmt in _stmts) {
      if (stmt.hasDataBinding) {
        buff.add(stmt.emitBoundElementFunction(boundElemIdx++));
      }
    }

    return buff.toString();
  }

  /**
   * Emit the entire component class.
   */
  String webComponentCode(ElemCG ecg, String constructorSignature) {
    var code = new WebComponentEmitter();
    code.constructor = constructorSignature;

    // Outer most template (main).
    emitTemplateStatements(code);

    // Iterate thru each template for each statement where there's an expression
    // emitting code for creating, inserting and removing for each component.
    CGBlock cgb;
    int templateIdx = 2;
    while ((cgb = ecg.templateCG(templateIdx++)) != null) {
      cgb.emitInnerTemplateStatements(code);
    }

    return code.toString();
  }

  void emitIfTemplateStatements(WebComponentEmitter code) {
    int boundElemIdx = 0;
    for (CGStatement stmt in _stmts) {
      if (boundElemIdx != 0) {
        if (stmt.hasDataBinding) {
          // Build the element variables.
          code.elemVars.add(stmt.emitWebComponentElementVariables());

          // Build the element listeners.
          code.otherVars.add(
              stmt.emitWebComponentListeners(boundElemIdx));

          // Build the created function body.
          code.createdStmts.add(stmt.emitWebComponentCreated());

          // Build the inserted function body.
          code.insertedStmts.add(
                stmt.emitWebComponentInserted(boundElemIdx));

          // Build the removed function body.
          code.removedStmts.add(
              stmt.emitWebComponentRemoved());

          boundElemIdx++;
        }
      } else {
        if (stmt.hasDataBinding) {
          // Build the element variables.
          code.elemVars.add(stmt.emitWebComponentElementVariables());

          // Build the element listeners.
          code.otherVars.add(
              stmt.emitWebComponentListeners(boundElemIdx));

          code.insertedStmts.add(emitIfTemplateInsert(stmt));
        }
      }
    }
  }

  String emitIfTemplateInsert(CGStatement stmt) {
    var ifInsertBody = new CodePrinter(1);

    final variableName = stmt.variableName;
    final listenerName = stmt.listenerName;
    final analyzer.ElementInfo info = stmt._info;

    StringBuffer listenerBody = new StringBuffer();
    bool listenerToCreate = false;

    info.events.forEach((name, eventInfo) {
      // TODO(terry,sigmund): this shouldn't refer to the component. The
      // action method should be resolved via lookup in the context of the
      // component's body (we need to make "if"s into closures, not classes).
      listenerBody.add("${eventInfo.action(variableName)};\n");
    });

    if (listenerBody.length > 0) {
      ifInsertBody.add("$listenerName = (_) {\n$listenerBody dispatch();\n};");
    }
    return ifInsertBody.toString();
  }

  void emitTemplateStatements(WebComponentEmitter code) {
    bool first = true;
    int boundElemIdx = 0;
    for (CGStatement stmt in _stmts) {
      if (stmt.hasDataBinding) {
        // Build the element variables.
        code.elemVars.add(stmt.emitWebComponentElementVariables());

        // Build the element listeners.
        code.otherVars.add(
            stmt.emitWebComponentListeners(boundElemIdx));

        // Build the created function body.
        code.createdStmts.add(stmt.emitWebComponentCreated());

        // Build the inserted function body.
        code.insertedStmts.add(
              stmt.emitWebComponentInserted(boundElemIdx));

        // Build the removed function body.
        code.removedStmts.add(
            stmt.emitWebComponentRemoved());

        boundElemIdx++;
      }
    }
  }

  /**
   * Generated class for a nested template. [parent] parentTemplate class name.
   */
  void emitInnerTemplateStatements(WebComponentEmitter code) {
    emitIfTemplateStatements(code);

    code.otherVars.add(emitTemplateWatcher());

    code.createdStmts.add(emitTemplateCreated());

    code.insertedStmts.add(emitTemplateIf());

    code.removedStmts.add(emitTemplateRemoved());
  }

  bool get conditionalTemplate => isTemplate && template.hasIfCondition;

  /** Emit watchers for a template conditional. */
  String emitTemplateWatcher() {
    if (!conditionalTemplate) return '';

    var templateId = getOrCreateElementId(templateElement, template);
    return '''
        WatcherDisposer _stopWatcher_if_${template.idAsIdentifier};
        Element _template_$templateId;
        Element _childTemplate;
        Element _parent;
        Element _child;
        String _childId;''';
  }

  /**
   * Emit creation of a template conditional, e.g.
   *
   *     <template instantiate="if anyDone">
   */
  String emitTemplateCreated() {
    if (!conditionalTemplate) return '';

    var id = getOrCreateElementId(templateElement, template);
    return '''
        _template_$id = root.query('#$id');
        assert(_template_$id.elements.length == 1);
        _childTemplate = _template_$id.elements[0];
        _childId = _childTemplate.id;
        if (_childId != null && _childId != '') _childTemplate.id = '';
        _template_$id.style.display = 'none';
        _template_$id.nodes.clear();''';
  }

  /** Emit the if conditional watcher. */
  String emitTemplateIf() {
    if (!conditionalTemplate) return '';

    // Compute the body.
    var tmplCode = new WebComponentEmitter();
    emitIfTemplateStatements(tmplCode);
    var body = emitTemplateIfBody();
    return "_stopWatcher_if_${template.idAsIdentifier} = bind("
           "() => ${template.ifCondition}, (e) {\n$body\n});\n";
  }

  /** Emit the code associated with the first element of the template if. */
  String emitTemplateIfBody() {
    var ifBody = new CodePrinter(3);

    // Use the first statement.
    CGStatement stmt = _stmts[0];
    if (stmt != null) {
      var templateId = getOrCreateElementId(templateElement, template);
      ifBody.add('''
          bool showNow = e.newValue;
          if (_child != null && !showNow) {
            _child.remove();
            _child = null;
          } else if (_child == null && showNow) {
            _child = _childTemplate.clone(true);
            if (_childId != null && _childId != '') _child.id = _childId;
            _template_$templateId.parent.nodes.add(_child);
          }''');

      ifBody.add("if (${stmt.variableName} != null) {");
      ifBody.add(stmt.emitWebComponentRemoved());
      ifBody.add("}\n");

      ifBody.add(stmt.emitWebComponentCreated());

      // TODO(terry): Need to handle multiple events on first element after
      //              template IF and multiple attributes and multiple template
      //              expressions in content (text nodes) as well.
      int watcherIdx = 0;
      bool eventHandled = false;

      final analyzer.ElementInfo info = stmt._info;
      info.events.forEach((name, eventInfo) {
        // TODO(jmesserly): throughout this file we hookup names via:
        //    .on['eventname']
        // instead of:
        //    .on.eventName
        // We do this because attribute names are not case sensitive in HTML,
        // and like the real DOM, our parser will canonicalize them to lower
        // case. Remove this workaround once we switch to the
        // `data-action="eventName:"` syntax.
        var listenerName = stmt.listenerName;
        var varName = stmt.variableName;
        ifBody.add('''
            if ($varName != null) {
              $varName.on['$name'].add($listenerName);''');
        eventHandled = true;
      });

      info.attributes.forEach((name, attrInfo) {
        watcherIdx++;
      });

      if (info.contentBinding != null) {
        String varName = stmt.variableName;
        String stopWatcherName = "_stopWatcher${varName}_$watcherIdx";
        var val = info.contentBinding;
        var innerHTML = info.contentExpression;
        ifBody.add('''
            $stopWatcherName = bind(() => $val, (e) {
              $varName.innerHTML = $innerHTML;
            });''');
        watcherIdx++;
      }
      if (eventHandled) {
        ifBody.add("}");
      }
    }

    return ifBody.toString();
  }

  /** Emit removal of any template conditional watchers. */
  String emitTemplateRemoved() {
    var printer = new CodePrinter(2);

    if (conditionalTemplate) {
      CGStatement stmt = _stmts[0];

      final analyzer.ElementInfo info = stmt._info;
      info.events.forEach((name, eventInfo) {
        var varName = stmt.variableName;
        var listenerName = stmt.listenerName;
        printer.add('''
            if ($varName != null) {
              $varName.on['$name'].remove($listenerName);
            }''');
      });

      printer.add("_stopWatcher_if_${template.idAsIdentifier}();");
      printer.add("if (_child != null) _child.remove();");
    }

    return printer.toString();
  }

}

int _globalGeneratedId = 0;
String getOrCreateElementId(Element element, analyzer.ElementInfo info) {
  var id = info.elementId;
  if (id == null) {
    // TODO(jmesserly): this logic probably belongs in the analyzer.
    // TODO(jmesserly): is it okay to mutate the tree like this?
    id = 'id${++_globalGeneratedId}';
    element.attributes['id'] = id;
    info.elementId = id;
  }
  return id;
}

// TODO(terry): Consider adding backpointer to block CGStatement is contained
//              in; no need to replicate things; like whether the statement is
//              in a repeat block (e.g., _repeating).
/**
 * CodeGen Statement used to manage each statement to be emited.  CGStatement
 * has the HTML (_elem) as well as the variable name of the parent element and
 * the varName (variable name) to be used to create this DOM element.
 */
class CGStatement {
  final bool _repeating;
  final StringBuffer _buff;
  Node _elem;
  analyzer.ElementInfo _info;
  final parentName;
  String variableName;
  bool _globalVariable;
  bool _closed;

  CGStatement(this._elem, this._info, this.parentName, varNameOrIndex,
      [bool exact = false, bool repeating = false])
      : _buff = new StringBuffer(),
        _closed = false,
        _repeating = repeating {

    if (varNameOrIndex is String) {
      // We have the global variable name
      variableName = varNameOrIndex;
      _globalVariable = true;
    } else {
      // local index generate local variable name.
      variableName = "_e${varNameOrIndex}";
      _globalVariable = false;
    }
  }

  bool get hasGlobalVariable => _globalVariable;

  String globalDeclaration() {
    if (hasGlobalVariable) {
      return (_repeating) ?
        "List ${variableName};             // Repeated elements.\n" :
        "var ${variableName};\n";
    }

    return "";
  }

  String globalInitializers() {
    if (hasGlobalVariable && _repeating) {
      return "${variableName} = [];\n";
    }

    return "";
  }

  void add(String value) {
    _buff.add(value);
  }

  bool get closed => _closed;

  void close() {
    if (_elem is Element && _elem is! DocumentType &&
        html5_constants.voidElements.indexOf(_elem.tagName) >= 0) {
      add("</${_elem.tagName}>");
    }
    _closed = true;
  }

  String emitStatement(int boundElemIdx) {
    var printer = new CodePrinter();

    String localVar = "";
    String tmpRepeat;
    if (hasGlobalVariable) {
      if (_repeating) {
        tmpRepeat = "tmp_${variableName}";
        localVar = "var ";
      }
    } else {
      localVar = "var ";
    }

    /* Emiting the following code fragment where varName is the attribute
       value for var=

          varName = new Element.html('HTML GOES HERE');
          parent.nodes.add(varName);

       for repeating elements in a #each:

          var tmp_nnn = new Element.html('HTML GOES HERE');
          varName.add(tmp_nnn);
          parent.nodes.add(tmp_nnn);

       for elements w/o var attribute set:

          var eNNN = new Element.html('HTML GOES HERE');
          parent.nodes.add(eNNN);
    */
    printer.add("");
    if (hasDataBinding) {
      // TODO(sigmund, terry): is this still needed?
      // printer.add("$spaces$localVar$varName = renderSetupFineGrainUpdates("
      //               "() => model.${exprs[0].name}, $boundElemIdx);\n");
    } else {
      bool isTextNode = _elem is Text;
      String createType = isTextNode ? "Text" : "Element.html";
      if (tmpRepeat == null) {
        printer.add("$localVar$variableName = new $createType(\'");
      } else {
        printer.add("$localVar$tmpRepeat = new $createType(\'");
      }
      if (_elem.tagName == 'template') {
        printer.add("<template></template>");
      } else {
        printer.add(isTextNode ?  _buff.toString().trim() : _buff.toString());
      }
      printer.add("\');\n");
    }

    if (tmpRepeat == null) {
      printer.add("$parentName.nodes.add($variableName);\n");
      if (_elem.tagName == 'template') {
        // TODO(terry): Need to support multiple templates either nested or
        //              siblings.
        // Hookup analyzer.TemplateInfo to the root.
        printer.add("root = $parentName;\n");
      }
    } else {
      printer.add("$parentName.nodes.add($tmpRepeat);\n"
                  "$variableName.add($tmpRepeat);\n");
    }

    return printer.toString();
  }

  String emitWebComponentElementVariables() {
    return "var $variableName;\n";
  }

  String emitWebComponentListeners(int index) {
    var declarations = new CodePrinter(1);
    int watcherIdx = 0;

    String listenerName = "_listener$variableName";

    // TODO(sigmund): create a listener per event type
    // TODO(sigmund): analyzer should merge together repeated listeners on the
    // same event type.
    bool emittedListener = false;
    bool emittedWatcher = false;

    // listeners associated with UI events:
    _info.events.forEach((name, eventInfo) {
      if (!emittedListener) {
        declarations.add("EventListener $listenerName;");
        emittedListener = true;
      }
    });

    // stop-functions for watchers associated with data-bound attributes
    _info.attributes.forEach((name, attrInfo) {
      for (int i = attrInfo.bindings.length; i > 0; i--) {
        declarations.add(
          "WatcherDisposer _stopWatcher${variableName}_$watcherIdx;");
        watcherIdx++;
      }
    });

    // stop-functions for watchers associated with data-bound content
    if (_info.contentBinding != null) {
      declarations.add(
          "WatcherDisposer _stopWatcher${variableName}_$watcherIdx;");
      watcherIdx++;
    }

    return declarations.toString();
  }

  /**
   * [prefix] is the prefix used for nested templates to get to methods/props
   * on the Component.
   */
  String emitWebComponentCreated([String prefix = ""]) {
    var id = getOrCreateElementId(_elem, _info);
    return "$variableName = ${prefix}root.query('#$id');\n";
  }

  String get listenerName => "_listener$variableName";

  /** Used for web components with template expressions {{expr}}. */
  String emitWebComponentInserted(int index) {
    var insertedBody = new CodePrinter(1);
    var listenerBody = new CodePrinter();

    // listeners associated with UI events:
    _info.events.forEach((name, eventInfo) {
      listenerBody.add('${eventInfo.action(variableName)};');
    });

    if (listenerBody.length > 0) {
      insertedBody.add('$listenerName = (_) {\n $listenerBody dispatch();\n};');
    }

    // attach event listeners
    // TODO(terry,sigmund): support more than one listener per element.
    _info.events.forEach((name, eventInfo) {
      var eventName = eventInfo.eventName;
      insertedBody.add("$variableName.on['$eventName'].add($listenerName);");
    });

    int watcherIdx = 0;
    // Emit stopWatchers.

    var stopWatcherPrefix = '_stopWatcher${variableName}_';
    // stop-functions for watchers associated with data-bound attributes
    _info.attributes.forEach((name, attrInfo) {
      if (attrInfo.isClass) {
        for (int i = 0; i < attrInfo.bindings.length; i++) {
          var exp = attrInfo.bindings[i];
          insertedBody.add('''
              $stopWatcherPrefix$watcherIdx = bind(() => $exp, (e) {
                if (e.oldValue != null && e.oldValue != '') {
                  $variableName.classes.remove(e.oldValue);
                }
                if (e.newValue != null && e.newValue != '') {
                  $variableName.classes.add(e.newValue);
                }
              });''');
          watcherIdx++;
        }
      } else {
        var val = attrInfo.boundValue;
        insertedBody.add('''
            $stopWatcherPrefix$watcherIdx = bind(() => $val, (e) {
              $variableName.$name = e.newValue;
            });''');
        watcherIdx++;
      }
    });

    // stop-functions for watchers associated with data-bound content
    if (_info.contentBinding != null) {
      var val = _info.contentBinding;
      insertedBody.add('''
          $stopWatcherPrefix$watcherIdx = bind(() => $val, (e) {
            $variableName.innerHTML = ${_info.contentExpression};
          });''');
      watcherIdx++;
    }

    return insertedBody.toString();
  }

  String emitWebComponentRemoved() {
    var removedBody = new CodePrinter();
    int watcherIdx = 0;

    // Detach event listeners.
    _info.events.forEach((name, eventInfo) {
      var eventName = eventInfo.eventName;
      removedBody.add("$variableName.on['$eventName'].remove($listenerName);");
    });

    // Call stop-watcher.
    _info.attributes.forEach((name, attrInfo) {
      for (int i = 0; i < attrInfo.bindings.length; i++) {
        removedBody.add('_stopWatcher${variableName}_$watcherIdx();');
        watcherIdx++;
      }
    });

    if (_info.contentBinding != null) {
      removedBody.add('_stopWatcher${variableName}_$watcherIdx();');
      watcherIdx++;
    }

    return removedBody.toString();
  }

  String emitBoundElementFunction(int index) {
    // Statements to update attributes associated with expressions.
    StringBuffer statementUpdateAttrs = new StringBuffer();
    var printer = new CodePrinter(1);

    printer.add("Element templateLine_$index(var e0) {");
    printer.add("  if (e0 == null) {\n");

    // Creation of DOM element.
    bool isTextNode = _elem is Text;
    String createType = isTextNode ? "Text" : "Element.html";
    var text = isTextNode ? _buff.toString().trim() : _buff.toString();
    printer.add("e0 = new $createType(\'$text\');");

    // TODO(terry): Fill in event hookup this is hacky.
    int idx = _info != null && _info.contentBinding != null ? 1 : 0;
    _elem.attributes.forEach((name, value) {
      if (_info.attributes[name] != null) {
        if (_elem.tagName == 'input') {
          if (name == "value") {
            // Hook up on keyup.
            printer.add(
              'e0.on.keyUp.add(wrap1((_) { model.${value} = e0.value; }));');
          } else if (name == "checked") {
            printer.add(
              'e0.on.click.add(wrap1((_) { model.${value} = e0.checked; }));');
          } else {
            // TODO(terry): Need to handle here with something...
            // data-on-XXXXX would handle on-change .on.change.add(listener);
            //assert(false);
          }
        }

        idx++;
        statementUpdateAttrs.add("e0.${name} = inject_$idx();");
      }
    });

    printer.add('}');
    printer.add(statementUpdateAttrs.toString());
    printer.add("return e0;\n}");

    return printer.toString();
  }

  bool get hasDataBinding => _info != null && _info.hasDataBinding;
}

/** Class for each code section of code emitted for a web component. */
class WebComponentEmitter {
  final StringBuffer elemVars;
  final StringBuffer otherVars;
  String constructor;
  final StringBuffer constructorStmts;
  final StringBuffer createdStmts;
  final StringBuffer insertedStmts;
  final StringBuffer removedStmts;

  WebComponentEmitter()
      : elemVars = new StringBuffer(),
        otherVars = new StringBuffer(),
        constructorStmts = new StringBuffer(),
        createdStmts = new StringBuffer(),
        insertedStmts = new StringBuffer(),
        removedStmts = new StringBuffer();

  String toString() {
    var componentBody = new CodePrinter(1);

    componentBody.add(elemVars.toString());
    componentBody.add(otherVars.toString());
    componentBody.add('');

    // Build the constructor function.
    if (constructorStmts.length == 0) {
      componentBody.add('$constructor;');
    } else {
      componentBody.add('''
          $constructor {
              $constructorStmts
          }''');
    }
    componentBody.add('');

    // Build the created function.
    componentBody.add('''
        void created(ShadowRoot shadowRoot) {
          root = shadowRoot;
          $createdStmts
        }''');
    componentBody.add('');

    // Build the inserted function.
    componentBody.add('void inserted() {\n $insertedStmts }');
    componentBody.add('');

    // Build the removed function.
    componentBody.add('void removed() {\n $removedStmts }');

    return componentBody.toString();
  }
}

// TODO(sigmund): delete this class entirely.
class Expression {
}

// TODO(terry): Consider merging ElemCG and Analyze.
/**
 * Code that walks the HTML tree.
 */
class ElemCG {
  // TODO(terry): Hacky, need to replace with real expression parser.
  /** List of identifiers and quoted strings (single and double quoted). */
  var identRe = const RegExp(
      @"""s*('"\'\"[^'"\'\"]+'"\'\"|[_A-Za-z][_A-Za-z0-9]*)""");

  bool _webComponent;

  /** Name of class if web component constructor attribute of element tag. */
  String _className;

  /** Name of the web component name attribute of element tag. */
  String _webComponentName;

  /** List of script tags with src. */
  final List<String> _includes;

  /** Dart script code associated with web component. */
  String _userCode;

  final List<CGBlock> _cgBlocks;

  /** Global var declarations for all blocks. */
  final StringBuffer _globalDecls;

  /** Global List var initializtion for all blocks in a #each. */
  final StringBuffer _globalInits;
  /**
   * List of injection function declarations.  Same expression used multiple
   * times has the same index in _expressions.
   */
  // TO-DELETE
  final List<Expression> _expressions;

  /**  List of each function declarations. */
  final List<String> repeats;

  /** List of web components to process <link rel=component>. */
  ProcessFiles processor;

  ElemCG(this.processor)
      : _webComponent = false,
        _includes = [],
        _expressions = [], // TO-DELETE
        repeats = [],
        _cgBlocks = [],
        _globalDecls = new StringBuffer(),
        _globalInits = new StringBuffer();

  bool get isWebComponent => _webComponent;
  String get className => _className;
  String get webComponentName => _webComponentName;
  List<String> get includes => _includes;
  String get userCode => _userCode;

  void reportError(String msg) {
    String filename = processor.current.cu.filename;
    world.error("$filename: $msg");
  }

  bool get isLastBlockConstructor {
    CGBlock block = _cgBlocks.last();
    return block.isConstructor;
  }

  String applicationCodeBody() {
    return getCodeBody(0);
  }

  CGBlock templateCG(int index) {
    if (index > 0) {
      return getCGBlock(index);
    }
  }

  bool pushBlock([Element templateElement]) {
    _cgBlocks.add(new CGBlock(processor, templateElement));
    return true;
  }

  void popBlock() {
    _globalDecls.add(lastBlock.globalDeclarations);
    _globalInits.add(lastBlock.globalInitializers);
    _cgBlocks.removeLast();
  }

  CGStatement pushStatement(var elem, var parentName) {
    return lastBlock.push(elem, parentName);
  }

  bool get closedStatement {
    return (lastBlock != null && lastBlock.last != null) ?
        lastBlock.last.closed : false;
  }

  void closeStatement() {
    if (lastBlock != null && lastBlock.last != null &&
        !lastBlock.last.closed) {
      lastBlock.last.close();
    }
  }

  String get lastVariableName {
    if (lastBlock != null && lastBlock.last != null) {
      return lastBlock.last.variableName;
    }
  }

  String get lastParentName {
    if (lastBlock != null && lastBlock.last != null) {
      return lastBlock.last.parentName;
    }
  }

  CGBlock get lastBlock => _cgBlocks.length > 0 ? _cgBlocks.last() : null;

  void add(String str) {
    _cgBlocks.last().add(str);
  }

  String get globalDeclarations {
    assert(_cgBlocks.length == 1);    // Only constructor body should be left.
    _globalDecls.add(lastBlock.globalDeclarations);
    return _globalDecls.toString();
  }

  String get globalInitializers {
    assert(_cgBlocks.length == 1);    // Only constructor body should be left.
    _globalInits.add(lastBlock.globalInitializers);
    return _globalInits.toString();
  }

  CGBlock getCGBlock(int idx) => idx < _cgBlocks.length ? _cgBlocks[idx] : null;

  String getCodeBody(int index) {
    CGBlock cgb = getCGBlock(index);
    return (cgb != null) ? cgb.codeBody : lastCodeBody;
  }

  String get lastCodeBody {
    closeStatement();
    return _cgBlocks.last().codeBody;
  }

  /**
   * Any element with this link tag:
   *     <link rel="component" href="webcomponent_file">
   * defines a web component file to process.
   */
  void queueUpFileToProcess(Element elem) {
    if (elem.tagName == 'link') {
      bool webComponent = elem.attributes['rel'] == 'components';
      String href = elem.attributes['href'];
      if (webComponent && href != null && href != '') {
        processor.add(href);
      }
    }
  }

  final String _DART_SCRIPT_TYPE = "application/dart";

  void emitScript(Element elem) {
    Expect.isTrue(elem.tagName == 'script');

    if (elem.attributes['type'] == _DART_SCRIPT_TYPE) {
      String includeName = elem.attributes["src"];
      if (includeName != null) {
        _includes.add(includeName);
      } else {
        Expect.isTrue(elem.nodes.length == 1);
        // This is the code to be emitted with the web component.
        _userCode = elem.nodes[0].value;
      }
    } else {
      reportError('tag ignored possibly missing type="$_DART_SCRIPT_TYPE"');
    }
  }

  /**
   * [scopeName] for expression.
   * [parentVarOrIndex] if # it's a local variable if string it's an exposed
   * name (specified by the var attribute) for this element.
   */
  emitElement(Node elem,
              [String scopeName = "",
               var parentVarOrIdx = 0,
               bool immediateNestedRepeat = false]) {
    if (elem.tagName == 'template') {
      emitTemplate(elem);
    } else if (elem is Element) {
      // Note: this check is always true right now, because DocumentFragment
      // does not extend Element in html5lib. This might change in the future
      // because in dart:html DocumentFragment extends Element
      // (this is unlike the real DOM, see:
      // http://www.w3.org/TR/DOM-Level-2-Core/core.html#ID-B63ED1A3).
      if (elem is! DocumentFragment) {
        // TODO(jmesserly): would be nice if we didn't have to grab info here.
        var info = processor.current.cu.info[elem];
        add("<${elem.tagName}${attributesToString(elem, info)}>");
      }
      String prevParent = lastVariableName;
      for (var childElem in elem.nodes) {
        if (childElem is Element) {
          closeStatement();
          emitConstructHtml(childElem, scopeName, prevParent);
          closeStatement();
        } else {
          emitElement(childElem, scopeName, parentVarOrIdx);
        }
      }

      // Close this tag.
      closeStatement();
    } else if (elem is Text) {
      String outputValue = elem.value.trim();
      if (outputValue.length > 0) {
        bool emitTextNode = false;
        if (closedStatement) {
          String prevParent = lastParentName;
          CGStatement stmt = pushStatement(elem, prevParent);
          emitTextNode = true;
        }

        // TODO(terry): Need to interpolate following:
        //      {sp}  → space
        //      {nil} → empty string
        //      {\r}  → carriage return
        //      {\n}  → new line (line feed)
        //      {\t}  → tab
        //      {lb}  → left brace
        //      {rb}  → right brace

        add("${outputValue}");            // remove leading/trailing whitespace.

        if (emitTextNode) {
          closeStatement();
        }
      }
    }
  }

  // TODO(terry): Hack prefixing all names with "${scopeName}." but don't touch
  //              quoted strings.
  String _resolveNames(String expr, String prefixPart) {
    StringBuffer newExpr = new StringBuffer();
    Iterable<Match> matches = identRe.allMatches(expr);

    int lastIdx = 0;
    for (Match m in matches) {
      if (m.start() > lastIdx) {
        newExpr.add(expr.substring(lastIdx, m.start()));
      }

      bool identifier = true;
      if (m.start() > 0)  {
        int charCode = expr.charCodeAt(m.start() - 1);
        // Starts with ' or " then it's not an identifier.
        identifier = charCode != 34 /* " */ && charCode != 39 /* ' */;
      }

      String strMatch = expr.substring(m.start(), m.end());
      if (identifier) {
        newExpr.add("${prefixPart}.${strMatch}");
      } else {
        // Quoted string don't touch.
        newExpr.add("${strMatch}");
      }
      lastIdx = m.end();
    }

    if (expr.length > lastIdx) {
      newExpr.add(expr.substring(lastIdx));
    }

    return newExpr.toString();
  }

  // TODO(terry): Might want to optimize if the other top-level nodes have no
  //              control structures (with, each, if, etc.). We could
  //              synthesize a root node and create all the top-level nodes
  //              under the root node with one innerHTML.
  /**
   * Construct the HTML; each top-level node get's it's own variable.
   */
  void emitConstructHtml(Node elem,
                         [String scopeName = "",
                          String parentName = "parent",
                          int varIndex = 0,
                          bool immediateNestedRepeat = false]) {
    if (elem is Element) {
      if (elem.tagName == "element") {
        _webComponent = true;

        String className = elem.attributes["constructor"];
        if (className != null) {
          _className = className;
        } else {
          reportError(
              "Web Component class name missing; use constructor attribute");
        }

        String wcName = elem.attributes["name"];
        if (wcName != null) {
          _webComponentName = wcName;
        } else {
          reportError("Missing name of Web Component use name attribute");
        }

        CGStatement stmt = pushStatement(elem, parentName);
        emitElement(elem, scopeName, stmt.hasGlobalVariable ?
            stmt.variableName : varIndex);
      } else if (elem.tagName == 'script') {
        // Never emit a script tag.
        emitScript(elem);
      } else if (elem.tagName == 'link') {
        queueUpFileToProcess(elem);
      } else {
        CGStatement stmt = pushStatement(elem, parentName);
        emitElement(elem, scopeName, stmt.hasGlobalVariable ?
            stmt.variableName : varIndex);
      }
    } else {
      // Text node.
      emitElement(elem, scopeName, varIndex, immediateNestedRepeat);
    }
  }

  /**
   * Any references to products.sales needs to be remaped to item.sales
   * for now it's a hack look for first dot and replace with item.
   */
  String repeatIterNameToItem(String iterName) {
    String newName = iterName;
    var dotForIter = iterName.indexOf('.');
    if (dotForIter >= 0) {
      newName = "_item${iterName.substring(dotForIter)}";
    }

    return newName;
  }

  void emitTemplate(Element elem) {
    if (!pushBlock(elem)) {
      reportError("Error at ${elem}");
    }

    for (var child in elem.nodes) {
      emitConstructHtml(child, "e0", "templateRoot");
    }
  }
}

// TODO(jmesserly): is there a better way to do this?
String attributesToString(Node node, analyzer.ElementInfo info) {
  if (node.attributes.length == 0) return '';

  var str = new StringBuffer();
  node.attributes.forEach((name, value) {
    // Skip data bound attributes, we'll deal with them separately.
    if (info.attributes[name] == null) {
      // TODO(jmesserly): need a convenience method in html5lib for escaping
      // html attributes.
      // Note: we don't use dart's htmlEscape function because it escapes more
      // things than we need. This is the same one used by html5lib.
      value = html5_utils.htmlEscapeMinimal(value, {'"': "&quot;"});
      str.add(' $name="$value"');
    }
  });
  return str.toString();
}
