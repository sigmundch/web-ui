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
    world.warning(
        'Error in $sourcePath line ${e.line}:${e.column}: ${e.message}');
  }
  return document;
}

/**
 * Walk the tree produced by the parser looking for templates, expressions, etc.
 * as a prelude to emitting the code for the template.
 */
class Compile {
  final FileSystem fs;
  final String baseDir;
  final ProcessFiles components;

  /** Used by template tool to open a file. */
  Compile(FileSystem filesystem, String path, String filename)
      : fs = filesystem,
        baseDir = path,
        components = new ProcessFiles() {
    components.add(filename, CompilationUnit.TYPE_MAIN);
    _compile();
  }

  /** Used by playground to analyze a memory buffer. */
  Compile.memory(FileSystem filesystem, String filename)
      : fs = filesystem,
        baseDir = "",
        components = new ProcessFiles() {
    components.add(filename, CompilationUnit.TYPE_MAIN);
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
            String source = fs.readAll("$baseDir/${process.cu.filename}");

            final parsedElapsed = time(() {
              process.cu.document = parseHtml(source, process.cu.filename);
            });
            if (options.showInfo) {
              printStats("Parsed", parsedElapsed, process.cu.filename);
            }
            if (options.dumpTree) {
              print("\n\n Dump Tree ${process.cu.filename}:\n\n");
              print(process.cu.document.toDebugString());
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
  /** Code type of this block. */
  final int _blockType;

  /** Optional local name for #each or #with. */
  final String _localName;

  final List<CGStatement> _stmts;

  /** Local variable index (e.g., e0, e1, etc.). */
  int _localIndex;

  final analyzer.TemplateInfo template;
  final Element templateElement;
  final ProcessFiles processor;

  // Block Types:
  static final int CONSTRUCTOR = 0;
  static final int REPEAT = 1;
  static final int TEMPLATE = 2;

  CGBlock([int indent = 4, int blockType = CGBlock.CONSTRUCTOR, local,
      this.processor])
      : template = null,
        templateElement = null,
        _stmts = <CGStatement>[],
        _localIndex = 0,
        _blockType = blockType,
        _localName = local {
    assert(_blockType >= CGBlock.CONSTRUCTOR && _blockType <= CGBlock.TEMPLATE);
  }
  CGBlock.createTemplate(Element templateElement,
      [int indent = 4, ProcessFiles processor])
      : templateElement = templateElement,
        processor = processor,
        template = processor.current.cu.info[templateElement],
        _stmts = <CGStatement>[],
        _localIndex = 0,
        _blockType = CGBlock.TEMPLATE,
        _localName = null;

  bool get hasStatements => !_stmts.isEmpty();
  bool get isConstructor => _blockType == CGBlock.CONSTRUCTOR;
  bool get isRepeat => _blockType == CGBlock.REPEAT;
  bool get isTemplate => _blockType == CGBlock.TEMPLATE;

  bool get hasLocalName => _localName != null;
  String get localName => _localName;

  /**
   * Each statement (HTML) encountered is remembered with either/both variable
   * name of parent and local name to associate with this element when the DOM
   * constructed.
   */
  CGStatement push(var elem, var parentName, [bool exact = false]) {
    var varName;
    final analyzer.ElementInfo info = processor.current.cu.info[elem];
    if (info != null) varName = info.idAsIdentifier;

    if (varName == null) {
      varName = _localIndex++;
    }

    CGStatement stmt = new CGStatement(elem, info, parentName, varName,
        exact, isRepeat);
    _stmts.add(stmt);

    return stmt;
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
    for (final CGStatement stmt in _stmts) {
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
    for (final CGStatement stmt in _stmts) {
      buff.add(stmt.globalInitializers());
    }

    return buff.toString();
  }

  String get codeBody {
    StringBuffer buff = new StringBuffer();

    // If statement is a bound element, has {{ }}, then boundElemIdx will match
    // the BoundElementEntry index associated with this element's statement.
    int boundElemIdx = 0;
    for (final CGStatement stmt in _stmts) {
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
    for (final CGStatement stmt in _stmts) {
      if (stmt.hasDataBinding) {
        buff.add(stmt.emitBoundElementFunction(boundElemIdx++));
      }
    }

    return buff.toString();
  }

  /**
   * Emit the entire component class.
   */
  List<String> webComponentCode(ElemCG ecg, String constructorSignature) {
    List<WebComponentEmitter> templatesCode = [];

    StringBuffer buff = new StringBuffer();

    buff.add("$genBoundElementsCommentBlock\n");

    WebComponentEmitter code = new WebComponentEmitter();

    code.constructor = constructorSignature;

    // Outer most template (main).
    emitTemplateStatements(code);
    templatesCode.add(code);

    // Iterate thru each template for each statement where there's an expression
    // emitting code for creating, inserting and removing for each component.
    CGBlock cgb;
    int templateIdx = 2;
    while ((cgb = ecg.templateCG(templateIdx++)) != null) {
      int emitIdx = templateIdx - 2;

      var templateCode = new WebComponentEmitter(true);

      // Emit the constructor.
      templateCode.constructor = "_Template_$emitIdx(this.component)";

      templatesCode.add(templateCode);

      // TODO(terry): Need to have a parent child template relationship only
      //              delegate from parent template to child template. Likewise,
      //              templates as siblings handled same way.

      // Construct and delegate from outer template to nested template.
      code.constructorStmts.add(
          "_template_$emitIdx = new _Template_$emitIdx(this);\n");

      // Delegate to the inner template.
      code.otherVars.add("_Template_$emitIdx _template_$emitIdx;\n");
      code.createdStmts.add("_template_$emitIdx.created(shadowRoot);\n");
      code.insertedStmts.add("_template_$emitIdx.inserted();\n");
      code.removedStmts.add("_template_$emitIdx.removed();\n");

      cgb.emitInnerTemplateStatements(ecg.className, templateCode);
    }

    List<String> allGeneratedCode = [];
    for (var code in templatesCode) {
      allGeneratedCode.add(code.toString());
    }
    return allGeneratedCode;
  }

  /*
    _stopWatcher_if_condition = bind(() => anyDone, (_) {
      if (_clearCompleted != null) {
        _clearCompleted.on.click.remove(_listener1);
        _stopWatcher_todoCount();
      }
      // TODO(sigmund): this feels too hacky. This node is under a conditional,
      // but it is not a component. We should probably wrap it in an artificial
      // component so we can call the lifecycle methods [created], [inserted]
      // and [removed] on it.
      _clearCompleted = root.query('#clear-completed');
      if (_clearCompleted != null) {
        _clearCompleted.on.click.add(_listener1);
        _stopWatcher_todoCount = bind(() => doneCount, (e) {
          _clearCompleted.innerHTML = 'Clear completed ${e.newValue}';
        });
      }
    });
   */
  void emitIfTemplateStatements(WebComponentEmitter code) {
    int boundElemIdx = 0;
    for (final CGStatement stmt in _stmts) {
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
      listenerBody.add("component.${eventInfo.action(variableName)};\n");
    });

    if (listenerBody.length > 0) {
      ifInsertBody.add("$listenerName = (_) {\n$listenerBody dispatch();\n};");
    }
    return ifInsertBody.toString();
  }

  void emitTemplateStatements(WebComponentEmitter code) {
    bool first = true;
    int boundElemIdx = 0;
    for (final CGStatement stmt in _stmts) {
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
  void emitInnerTemplateStatements(String parent, WebComponentEmitter code) {
    // The component to delegate all calls.
    code.elemVars.add("$parent component;\n");

    emitIfTemplateStatements(code);

    code.otherVars.add(emitTemplateWatcher());

    code.createdStmts.add(emitTemplateCreated());

    code.insertedStmts.add(emitTemplateIf());

    code.removedStmts.add(emitTemplateRemoved());
  }

  bool get conditionalTemplate => isTemplate && template.isConditional
      && templateElement.attributes.length > 0;

  /** Emit watchers for a template conditional. */
  String emitTemplateWatcher() {
    if (conditionalTemplate) {
      for (var name in templateElement.attributes.getKeys()) {
        if (name == "id") {
          var value = templateElement.attributes[name];
          return "WatcherDisposer _stopWatcher_if_$value;\n";
        }
      }
    }
    return "";
  }

  /**
   * Emit creation of a template conditional.
   */
  String emitTemplateCreated() {
    if (conditionalTemplate) {
      for (var name in templateElement.attributes.getKeys()) {
        if (name == "id") {
          var tmplId = templateElement.attributes[name];
          var ifExpr = template.instantiate;
          // analyzer.TemplateInfo conditional e.g.,
          //
          //    <template instantiate="if anyDone" is="x-if" id='done'>
          //
          // Emit statements:
          //
          //    var done = manager[component.root.query('#done')];
          //    done.shouldShow = (_) => component.anyDone
          return "var $tmplId = manager[component.root.query('#$tmplId')];\n"
              "$tmplId.shouldShow = (_) => component.$ifExpr;\n";
        }
      }
    }
    return "";
  }

  /** Emit the if conditional watcher. */
  String emitTemplateIf() {
    if (conditionalTemplate) {
      // Compute the body.
      WebComponentEmitter tmplCode = new WebComponentEmitter();
      emitIfTemplateStatements(tmplCode);
      for (var name in templateElement.attributes.getKeys()) {
        if (name == "id") {
          var tmplId = templateElement.attributes[name];
          var ifExpr = template.instantiate;
          var body = emitTemplateIfBody();
          return "_stopWatcher_if_$tmplId = component.bind("
                 "() => component.$ifExpr, (_) {\n$body\n});\n";
        }
      }
    }
    return "";
  }

  /** Emit the code associated with the first element of the template if. */
  String emitTemplateIfBody() {
    var ifBody = new CodePrinter(3);

    // Use the first statement.
    final CGStatement stmt = _stmts[0];
    if (stmt != null) {
      ifBody.add("if (${stmt.variableName} != null) {");
      ifBody.add(stmt.emitWebComponentRemoved());
      ifBody.add("}\n");

      ifBody.add(stmt.emitWebComponentCreated("component."));

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
        // TODO(terry,sigmund): remove this hack for 'component.'
        innerHTML = innerHTML.replaceAll(@'${', @'${component.');
        ifBody.add('''
            $stopWatcherName = component.bind(() => component.$val, (e) {
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
      final CGStatement stmt = _stmts[0];

      final analyzer.ElementInfo info = stmt._info;
      info.events.forEach((name, eventInfo) {
        var varName = stmt.variableName;
        var listenerName = stmt.listenerName;
        printer.add('''
            if ($varName != null) {
              $varName.on['$name'].remove($listenerName);
            }''');
      });

      for (var name in templateElement.attributes.getKeys()) {
        if (name == "id") {
          var tmplId = templateElement.attributes[name];
          var ifExpr = template.instantiate;
          var body = emitTemplateIfBody();
          printer.add("_stopWatcher_if_$tmplId();");
        }
      }
    }

    return printer.toString();
  }

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
  var parentName;
  String varName;
  bool _globalVariable;
  bool _closed;

  CGStatement(this._elem, this._info, this.parentName, varNameOrIndex,
      [bool exact = false, bool repeating = false]) :
        _buff = new StringBuffer(),
        _closed = false,
        _repeating = repeating {

    if (varNameOrIndex is String) {
      // We have the global variable name
      varName = varNameOrIndex;
      _globalVariable = true;
    } else {
      // local index generate local variable name.
      varName = "e${varNameOrIndex}";
      _globalVariable = false;
    }
  }

  bool get hasGlobalVariable => _globalVariable;
  String get variableName => varName;

  String globalDeclaration() {
    if (hasGlobalVariable) {
      return (_repeating) ?
        "List ${varName};             // Repeated elements.\n" :
        "var ${varName};\n";
    }

    return "";
  }

  String globalInitializers() {
    if (hasGlobalVariable && _repeating) {
      return "${varName} = [];\n";
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
        tmpRepeat = "tmp_${varName}";
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
        printer.add("$localVar$varName = new $createType(\'");
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
      printer.add("$parentName.nodes.add($varName);\n");
      if (_elem.tagName == 'template') {
        // TODO(terry): Need to support multiple templates either nested or
        //              siblings.
        // Hookup analyzer.TemplateInfo to the root.
        printer.add("root = $parentName;\n");
      }
    } else {
      printer.add("$parentName.nodes.add($tmpRepeat);\n"
                    "$varName.add($tmpRepeat);\n");
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
    String elemId = _info != null ? _info.elementId : null;
    return (elemId != null) ?
        "$variableName = ${prefix}root.query('#$elemId');\n" : "";
  }

  bool isEventAttribute(String attributeName) =>
      attributeName.startsWith(analyzer.DATA_ON_ATTRIBUTE);

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
  String constructorSignature;
  final StringBuffer constructorStmts;
  final StringBuffer createdStmts;
  final StringBuffer insertedStmts;
  final StringBuffer removedStmts;
  final String _delegate;

  WebComponentEmitter([bool innerTemplate = false])
      : elemVars = new StringBuffer(),
        otherVars = new StringBuffer(),
        constructorStmts = new StringBuffer(),
        createdStmts = new StringBuffer(),
        insertedStmts = new StringBuffer(),
        removedStmts = new StringBuffer(),
        _delegate = innerTemplate ? "component." : "";

  void set constructor(String constructSig) {
    constructorSignature = constructSig;
  }

  String toString() {
    var componentBody = new CodePrinter(1);

    componentBody.add(elemVars.toString());
    componentBody.add(otherVars.toString());
    componentBody.add('');

    // Build the constructor function.
    if (constructorStmts.length == 0) {
      componentBody.add('$constructorSignature;');
    } else {
      componentBody.add('''
          $constructorSignature {
              ${constructorStmts}
          }''');
    }
    componentBody.add('');

    // Build the created function.
    componentBody.add('''
        void created(ShadowRoot shadowRoot) {
          ${_delegate}root = shadowRoot;
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

  List<String> activeBlocksLocalNames() {
    List<String> result = [];

    for (final CGBlock block in _cgBlocks) {
      if (block.isRepeat && block.hasLocalName) {
        result.add(block.localName);
      }
    }

    return result;
  }

  /**
   * Active block with this localName.
   */
  bool matchBlocksLocalName(String name) =>
      _cgBlocks.some((block) => block.isRepeat &&
                                block.hasLocalName &&
                                block.localName == name);

  /**
   * Any active blocks?
   */
  bool isNestedBlock() =>
      _cgBlocks.some((block) => block.isRepeat);

  /**
   * Any active blocks with localName?
   */
  bool isNestedNamedBlock() =>
      _cgBlocks.some((block) => block.isRepeat && block.hasLocalName);

  // Any current active #each blocks.
  bool anyRepeatBlocks() =>
      _cgBlocks.some((block) => block.isRepeat);

  bool pushBlock([int indent = 4, int blockType = CGBlock.CONSTRUCTOR,
                  String itemName = null]) {
    if (itemName != null && matchBlocksLocalName(itemName)) {
      reportError("Active block already exist with local name: ${itemName}.");
      return false;
    } else if (itemName == null && this.isNestedBlock()) {
      reportError('''
Nested iterates must have a localName;
 \n  #each list [localName]\n  #with object [localName]''');
      return false;
    }
    _cgBlocks.add(
        new CGBlock(indent, blockType, itemName, processor));

    return true;
  }

  bool pushTemplate(int indent, Element elem) {
    _cgBlocks.add(new CGBlock.createTemplate(elem, indent, processor));
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

  void emitIncludes() {

  }

  bool matchExpression() {

  }

  // TODO(sigmund,terry): discuss about what we'll do about inject_, can we
  // delete this function entirely?
  void emitExpressions(TemplateExpression elem, String scopeName) {
/*
// TO-DELETE
    if (isWebComponent) {
      _expressions.add(new Expression(elem.expression));
    } else {
      StringBuffer func = new StringBuffer();
      String newExpr = elem.expression;
      bool anyNesting = isNestedNamedBlock();
      if (scopeName.length > 0 && !anyNesting) {
        // In a block #command need the scope passed in.
        add("\$\{inject_${_expressions.length}(_item)\}");
        func.add("\n  String inject_${_expressions.length
          }(var _item) {\n");
        // Escape all single-quotes, this expression is embedded as a string
        // parameter for the call to safeHTML.
        newExpr = _resolveNames(newExpr.replaceAll("'", "\\'"), "_item");
      } else {
        // Not in a block #command item isn't passed in.
        add("\$\{inject_${_expressions.length}()\}");
        func.add("\n  String inject_${_expressions.length}() {\n");

        if (anyNesting) {
          func.add(defineScopes());
        }
      }

      // Construct the active scope names for name resolution.
      func.add("    return safeHTML('\$\{${newExpr}\}');\n");
      func.add("  }\n");

      _expressions.add(new Expression(func.toString()));
    }
// end TO-DELETE
*/
  }

  void emitTemplate(Element elem) {
    if (!pushTemplate(6, elem)) {
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

/** Helper class that auto-formats generated code. */
class CodePrinter {
  int _indent;
  StringBuffer _buff;
  CodePrinter([initialIndent = 0])
      : _indent = initialIndent, _buff = new StringBuffer();

  void add(String lines) {
    lines.split('\n').forEach((line) => _add(line.trim()));
  }

  void _add(String line) {
    bool decIndent = line.startsWith("}");
    bool incIndent = line.endsWith("{");
    if (decIndent) _indent--;
    for (int i = 0; i < _indent; i++) _buff.add('  ');
    _buff.add(line);
    _buff.add('\n');
    if (incIndent) _indent++;
  }

  void inc([delta = 1]) { _indent += delta; }
  void dec([delta = 1]) { _indent -= delta; }

  String toString() => _buff.toString();

  int get length => _buff.length;
}
