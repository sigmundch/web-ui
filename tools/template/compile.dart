// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('analysis');

#import('dart:coreimpl');
#import('../../lib/html5parser/tokenkind.dart');
#import('../../lib/html5parser/htmltree.dart');
#import('../css/css.dart', prefix:'css');
#import('../lib/file_system.dart');
#import('../lib/world.dart');
#import('codegen.dart');
#import('codegen_application.dart');
#import('codegen_component.dart');
#import('compilation_unit.dart');
#import('processor.dart');
#import('template.dart');
#import('utils.dart');
#import('analyzer.dart', prefix: 'analyzer');


// TODO(terry): Too many classes in this file need to break up walking, analysis
//              and codegen to different files (started but needs to finished).

/**
 * Walk the tree produced by the parser looking for templates, expressions, etc.
 * as a prelude to emitting the code for the template.
 */
class Compile {
  final FileSystem fs;
  final String baseDir;
  final ProcessFiles components;

  // TODO(terry): Hacky use package: when we're part of the SDK.
  /** Number of ../ to find dart-web-components directory. */
  final int _parentsPathCount;

  /** Used by template tool to open a file. */
  Compile(FileSystem filesystem, String path, String filename, int parentsCnt)
      : fs = filesystem,
        baseDir = path,
        _parentsPathCount = parentsCnt,
        components = new ProcessFiles() {
    components.add(filename, CompilationUnit.TYPE_MAIN);
    _compile();
  }

  /** Used by playground to analyze a memory buffer. */
  Compile.memory(FileSystem filesystem, String filename, int parentsCnt)
      : fs = filesystem,
        baseDir = "",
        _parentsPathCount = parentsCnt,
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
              process.cu.document = templateParseAndValidate(source);
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
  void _walkTree(HTMLDocument doc, ElemCG ecg) {
    if (!ecg.pushBlock()) {
      world.error("Error at ${doc.children}");
    }

    var start;
    // Skip the fragment (root) if it exist and the HTML node as well.
    if (doc.children.length > 0 && doc.children[0] is HTMLElement) {
      HTMLElement elem = doc.children[0];
      if (elem.isFragment) {
        start = elem;
        for (var child in start.children) {
          if (child is HTMLText) {
            continue;
          } else if (child is HTMLElement) {
            if (child.tagTokenId == TokenKind.HTML_ELEMENT) {
              start = child;
            }
            break;
          }
        }
      }
    } else {
      start = doc;
    }

    bool firstTime = true;
    for (var child in start.dynamic.children) {
      if (child is HTMLText) {
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
      return CodegenComponent.generate(_parentsPathCount, libraryName,
          cu.filename, cu.elemCG);
    } else {
      return CodegenApplication.generate(_parentsPathCount, libraryName,
          cu.filename, cu.elemCG);
    }
  }

  String _emitterHTML(ProcessFile process) {
    // TODO(terry): Need special emitter for main vs web component.
    return process.cu.document.generateHTML();
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

  /** Number of spaces to prefix for each statement. */
  final int _indent;

  /** Optional local name for #each or #with. */
  final String _localName;

  final List<CGStatement> _stmts;

  /** Local variable index (e.g., e0, e1, etc.). */
  int _localIndex;

  Template _template;    // If template remember
  final ProcessFiles processor;

  // Block Types:
  static final int CONSTRUCTOR = 0;
  static final int REPEAT = 1;
  static final int TEMPLATE = 2;

  CGBlock([int indent = 4, int blockType = CGBlock.CONSTRUCTOR, local,
      this.processor])
      : _stmts = new List<CGStatement>(),
        _localIndex = 0,
        _indent = indent,
        _blockType = blockType,
        _localName = local {
    assert(_blockType >= CGBlock.CONSTRUCTOR && _blockType <= CGBlock.TEMPLATE);
  }
  CGBlock.createTemplate(Template template, [int indent = 4, this.processor])
      : _template = template,
        _stmts = new List<CGStatement>(),
        _localIndex = 0,
        _indent = indent,
        _blockType = CGBlock.TEMPLATE,
        _localName = null;

  bool get hasStatements => !_stmts.isEmpty();
  bool get isConstructor => _blockType == CGBlock.CONSTRUCTOR;
  bool get isRepeat => _blockType == CGBlock.REPEAT;
  bool get isTemplate => _blockType == CGBlock.TEMPLATE;

  bool get hasLocalName => _localName != null;
  String get localName => _localName;

  Template get template => _template;

  /**
   * Each statement (HTML) encountered is remembered with either/both variable
   * name of parent and local name to associate with this element when the DOM
   * constructed.
   */
  CGStatement push(var elem, var parentName, [bool exact = false]) {
    var varName;
    var info = processor.current.cu.info[elem];
    if (info != null) varName = info.idAsIdentifier;

    if (varName == null) {
      varName = _localIndex++;
    }

    CGStatement stmt = new CGStatement(elem, info, _indent, parentName, varName,
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
        if (stmt.hasTemplateExpression) {
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
      if (stmt.hasTemplateExpression) {
        boundElemIdx++;
      }
    }

    return buff.toString();
  }

  static String genBoundElementsCommentBlock = @"""


  // ==================================================================
  // Tags that contains a template expression {{ nnnn }}.
  // ==================================================================""";

  String templatesCodeBody(List<Expression> expressions) {
    StringBuffer buff = new StringBuffer();

    buff.add(genBoundElementsCommentBlock);

    int boundElemIdx = 0;   // Index if statement is a bound elem has a {{ }}.
    for (final CGStatement stmt in _stmts) {
      if (stmt.hasTemplateExpression) {
        buff.add(stmt.emitBoundElementFunction(expressions, boundElemIdx++));
      }
    }

    return buff.toString();
  }

  /**
   * Emit the entire component class.
   */
  List<String> webComponentCode(ElemCG ecg, String constructorSignature) {
    List<WebComponentEmitter> templatesCode = [];

    String spaces = Codegen.spaces(2);

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
          "$spaces  _template_$emitIdx = new _Template_$emitIdx(this);\n");

      // Delegate to the inner template.
      code.otherVars.add("${spaces}_Template_$emitIdx _template_$emitIdx;\n");
      code.createdStmts.add(
          "$spaces  _template_$emitIdx.created(shadowRoot);\n");
      code.insertedStmts.add("$spaces  _template_$emitIdx.inserted();\n");
      code.removedStmts.add("$spaces  _template_$emitIdx.removed();\n");

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
        if (stmt.hasTemplateExpression) {
          var exprs = stmt.attributesExpressions(true);

          // Build the element variables.
          code.elemVars.add(stmt.emitWebComponentElementVariables());

          // Build the element listeners.
          code.otherVars.add(
              stmt.emitWebComponentListeners(exprs, boundElemIdx));

          // Build the created function body.
          code.createdStmts.add(stmt.emitWebComponentCreated());

          // Build the inserted function body.
          code.insertedStmts.add(
                stmt.emitWebComponentInserted(exprs, boundElemIdx));

          // Build the removed function body.
          code.removedStmts.add(
              stmt.emitWebComponentRemoved(exprs));

          boundElemIdx++;
        }
      } else {
        if (stmt.hasTemplateExpression) {
          var exprs = stmt.attributesExpressions(true);

          // Build the element variables.
          code.elemVars.add(stmt.emitWebComponentElementVariables());

          // Build the element listeners.
          code.otherVars.add(
              stmt.emitWebComponentListeners(exprs, boundElemIdx));

          code.insertedStmts.add(emitIfTemplateInsert(exprs, stmt));
        }
      }
    }
  }

  String emitIfTemplateInsert(List<Expression> expressions, CGStatement stmt) {
    String spaces = Codegen.spaces(2);

    StringBuffer statement = new StringBuffer();

    final variableName = stmt.variableName;
    final listenerName = stmt.listenerName;
    final info = stmt._info;

    StringBuffer listenerBody = new StringBuffer();
    bool listenerToCreate = false;

    info.events.forEach((name, eventInfo) {
      // TODO(terry,sigmund): this shouldn't refer to the component. The
      // action method should be resolved via lookup in the context of the
      // component's body (we need to make "if"s into closures, not classes).
      listenerBody.add(
        "$spaces    component.${eventInfo.action(variableName)};\n");
    });

    if (listenerBody.length > 0) {
      statement.add("$spaces  $listenerName = (_) {\n"
                    "$listenerBody"
                    "$spaces    dispatch();\n"
                    "$spaces  };\n");
    }
    return statement.toString();
  }

  void emitTemplateStatements(WebComponentEmitter code) {
    bool first = true;
    int boundElemIdx = 0;
    for (final CGStatement stmt in _stmts) {
      if (stmt.hasTemplateExpression) {
        // TODO(terry): Consider caching expressions for each statement instead
        //              of constructing each time.
        var exprs = stmt.attributesExpressions();

        // Build the element variables.
        code.elemVars.add(stmt.emitWebComponentElementVariables());

        // Build the element listeners.
        code.otherVars.add(
            stmt.emitWebComponentListeners(exprs, boundElemIdx));

        // Build the created function body.
        code.createdStmts.add(stmt.emitWebComponentCreated());

        // Build the inserted function body.
        code.insertedStmts.add(
              stmt.emitWebComponentInserted(exprs, boundElemIdx));

        // Build the removed function body.
        code.removedStmts.add(
            stmt.emitWebComponentRemoved(exprs));

        boundElemIdx++;
      }
    }
  }

  /**
   * Generated class for a nested template. [parent] parentTemplate class name.
   */
  void emitInnerTemplateStatements(String parent, WebComponentEmitter code) {
    String spaces = Codegen.spaces(2);

    // The component to delegate all calls.
    code.elemVars.add("$spaces$parent component;\n");

    emitIfTemplateStatements(code);

    code.otherVars.add(emitTemplateWatcher());

    code.createdStmts.add(emitTemplateCreated());

    code.insertedStmts.add(emitTemplateIf());

    code.removedStmts.add(emitTemplateRemoved());
  }

  bool get conditionalTemplate =>
      isTemplate && template.isConditional && template.anyAttributes;

  /** Emit watchers for a template conditional. */
  String emitTemplateWatcher() {
    String spaces = Codegen.spaces(2);
    if (conditionalTemplate) {
      for (var attr in template.attributes) {
        if (attr.name == "id") {
          var tmplId = attr.value;
          var ifExpr = template.instantiate;

          return "${spaces}WatcherDisposer _stopWatcher_if_$tmplId;\n";
        }
      }
    }
    return "";
  }

  /**
   * Emit creation of a template conditional.
   */
  String emitTemplateCreated() {
    String spaces = Codegen.spaces(2);
    if (conditionalTemplate) {
      for (var attr in template.attributes) {
        if (attr.name == "id") {
          var tmplId = attr.value;
          var ifExpr = template.instantiate;
          // Template conditional e.g.,
          //
          //    <template instantiate="if anyDone" is="x-if" id='done'>
          //
          // Emit statements:
          //
          //    var done = manager[component.root.query('#done')];
          //    done.shouldShow = (_) => component.anyDone
          return
              "$spaces  var $tmplId = manager[component.root.query('#${tmplId
              }')];\n  $spaces$tmplId.shouldShow = (_) => component.$ifExpr;\n";
        }
      }
    }
    return "";
  }

  /** Emit the if conditional watcher. */
  String emitTemplateIf() {
    String spaces = Codegen.spaces(4);
    if (conditionalTemplate) {
      // Compute the body.
      WebComponentEmitter tmplCode = new WebComponentEmitter();
      emitIfTemplateStatements(tmplCode);
      for (var attr in template.attributes) {
        if (attr.name == "id") {
          var tmplId = attr.value;
          var ifExpr = template.instantiate;
          var body = emitTemplateIfBody();
          return
              "${spaces}_stopWatcher_if_${tmplId
              } = component.bind(() => component.${ifExpr}, (_) {\n${body
              }\n$spaces});\n";
        }
      }
    }
    return "";
  }

  /** Emit the code associated with the first element of the template if. */
  String emitTemplateIfBody() {
    String spaces = Codegen.spaces(6);
    StringBuffer buff = new StringBuffer();

    // Use the first statement.
    final CGStatement stmt = _stmts[0];
    List<Expression> expressions = stmt.attributesExpressions(true);
    if (stmt != null) {
      buff.add("${spaces}if (${stmt.variableName} != null) {\n");
      buff.add(stmt.emitWebComponentRemoved(expressions, spaces));
      buff.add("$spaces}\n\n");

      buff.add(stmt.emitWebComponentCreated(spaces, "component."));

      // TODO(terry): Need to handle multiple events on first element after
      //              template IF and multiple attributes and multiple template
      //              expressions in content (text nodes) as well.
      int watcherIdx = 0;
      bool eventHandled = false;

      var info = stmt._info;
      info.events.forEach((name, eventInfo) {
        var listenerName = stmt.listenerName;
        var varName = stmt.variableName;
        buff.add("${spaces}if ($varName != null) {\n");
        buff.add("$spaces  $varName.on.$name.add($listenerName);\n");
        eventHandled = true;
      });

      info.attributes.forEach((name, attrInfo) {
        watcherIdx++;
      });

      if (info.contentBinding != null) {
        String varName = stmt.variableName;
        String stopWatcherName = "_stopWatcher${varName}_$watcherIdx";
        var innerHTML = info.contentExpression;
        // TODO(terry,sigmund): remove this hack for 'component.'
        innerHTML = innerHTML.replaceAll(@'${', @'${component.');
        buff.add(
            "$spaces  $stopWatcherName ="
            " component.bind(() => component.${info.contentBinding}, (e) {\n"
            "${spaces}    $varName.innerHTML = $innerHTML;\n"
            "${spaces}  });\n");
        watcherIdx++;
      }
      if (eventHandled) {
        buff.add("$spaces}\n");
      }
    }

    return buff.toString();
  }

  /** Emit removal of any template conditional watchers. */
  String emitTemplateRemoved() {
    String spaces = Codegen.spaces(4);

    StringBuffer buff = new StringBuffer();

    if (conditionalTemplate) {
      final CGStatement stmt = _stmts[0];
      List<Expression> expressions = stmt.attributesExpressions();

      stmt._info.events.forEach((name, eventInfo) {
        var varName = stmt.variableName;
        buff.add("${spaces}if ($varName != null) {\n");
        buff.add("$spaces  $varName.on.$name.remove(${stmt.listenerName});\n");
        buff.add("$spaces}\n");
      });

      for (var attr in template.attributes) {
        if (attr.name == "id") {
          var tmplId = attr.value;
          var ifExpr = template.instantiate;
          var body = emitTemplateIfBody();
          buff.add("${spaces}_stopWatcher_if_$tmplId();\n");
        }
      }
    }

    return buff.toString();
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
  static const String NEW_LINE = '\n';

  final bool _repeating;
  final StringBuffer _buff;
  TreeNode _elem;
  analyzer.NodeInfo _info;
  int _indent;
  var parentName;
  String varName;
  bool _globalVariable;
  bool _closed;

  CGStatement(this._elem, this._info,
      this._indent, this.parentName, varNameOrIndex,
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
      String spaces = Codegen.spaces(_indent);
      return (_repeating) ?
        "  List ${varName};             // Repeated elements.$NEW_LINE" :
        "  var ${varName};$NEW_LINE";
    }

    return "";
  }

  String globalInitializers() {
    if (hasGlobalVariable && _repeating) {
      return "    ${varName} = [];$NEW_LINE";
    }

    return "";
  }

  void add(String value) {
    _buff.add(value);
  }

  bool get closed => _closed;

  void close() {
    if (_elem is HTMLElement && _elem.scoped) {
      add("</${_elem.tagName}>");
    }
    _closed = true;
  }

  /** Find all attributes associated with a template expression. */
  // TODO(sigmund): delete completely
  List<Expression> attributesExpressions([bool innerTemplate = false]) =>
      const [];

  String emitStatement(int boundElemIdx) {
    StringBuffer statement = new StringBuffer();

    String spaces = Codegen.spaces(_indent);

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
    if (hasTemplateExpression) {
      List<Expression> exprs = attributesExpressions();
      // TODO(terry): Need to handle > one attribute expression per line.
      statement.add("$NEW_LINE$spaces${
        localVar}$varName = renderSetupFineGrainUpdates(() => model.${
        exprs[0].name}, $boundElemIdx);");
    } else {
      bool isTextNode = _elem is HTMLText;
      String createType = isTextNode ? "Text" : "Element.html";
      if (tmpRepeat == null) {
        statement.add("$NEW_LINE$spaces$localVar$varName = new $createType(\'");
      } else {
        statement.add(
            "$NEW_LINE$spaces$localVar$tmpRepeat = new $createType(\'");
      }
      if (_elem is Template) {
        statement.add("<template></template>");
      } else {
        statement.add(isTextNode ?
            _buff.toString().trim() : _buff.toString());
      }
      statement.add("\');");
    }

    if (tmpRepeat == null) {
      statement.add("$NEW_LINE$spaces$parentName.nodes.add($varName);");
      if (_elem is Template) {
        // TODO(terry): Need to support multiple templates either nested or
        //              siblings.
        // Hookup Template to the root.
        statement.add("$NEW_LINE${spaces}root = $parentName;");
      }
    } else {
      statement.add("$NEW_LINE$spaces$parentName.nodes.add($tmpRepeat);");
      statement.add("$NEW_LINE$spaces$varName.add($tmpRepeat);");
    }

    return statement.toString();
  }

  String emitWebComponentElementVariables() {
    String spaces = Codegen.spaces(2);
    return "${spaces}var $variableName;$NEW_LINE";
  }

  String emitWebComponentListeners(List<Expression> expressions, int index) {
    String spaces = Codegen.spaces(2);

    StringBuffer declLines = new StringBuffer();

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
        declLines.add("${spaces}EventListener $listenerName;\n");
        emittedListener = true;
      }
    });

    // stop-functions for watchers associated with data-bound attributes
    _info.attributes.forEach((name, attrInfo) {
      for (int i = attrInfo.bindings.length; i > 0; i--) {
        declLines.add("${spaces}WatcherDisposer "
                      "_stopWatcher${variableName}_$watcherIdx;\n");
        watcherIdx++;
      }
    });

    // stop-functions for watchers associated with data-bound content
    if (_info.contentBinding != null) {
      declLines.add("${spaces}WatcherDisposer "
                    "_stopWatcher${variableName}_$watcherIdx;\n");
      watcherIdx++;
    }

    return declLines.toString();
  }

  /**
   * [prefix] is the prefix used for nested templates to get to methods/props
   * on the Component.
   */
  String emitWebComponentCreated([String indent = null, String prefix = ""]) {
    String spaces = indent == null ? Codegen.spaces(4) : indent;
    String elemId = _info != null ? _info.elementId : null;

    return (elemId != null) ?
        "$spaces$variableName = ${prefix}root.query('#$elemId');$NEW_LINE" : "";
  }

  bool isEventAttribute(String attributeName) =>
      attributeName.startsWith(DATA_ON_ATTRIBUTE);

  String get listenerName => "_listener$variableName";

  /** Used for web components with template expressions {{expr}}. */
  String emitWebComponentInserted(List<Expression> expressions, int index) {
    String spaces = Codegen.spaces(2);

    StringBuffer statement = new StringBuffer();

    StringBuffer listenerBody = new StringBuffer();

    // listeners associated with UI events:
    _info.events.forEach((name, eventInfo) {
      listenerBody.add("$spaces    ${eventInfo.action(variableName)};\n");
    });

    if (listenerBody.length > 0) {
      statement.add("$spaces  $listenerName = (_) {$NEW_LINE"
                    "$listenerBody"
                    "$spaces    dispatch();$NEW_LINE"
                    "$spaces  };$NEW_LINE");
    }

    // attach event listeners
    // TODO(terry,sigmund): support more than one listener per element.
    _info.events.forEach((name, eventInfo) {
      var eventName = eventInfo.eventName;
      statement.add(
        "$spaces  $variableName.on.${eventName}.add($listenerName);\n");
    });

    int watcherIdx = 0;
    // Emit stopWatchers.

    // stop-functions for watchers associated with data-bound attributes
    _info.attributes.forEach((name, attrInfo) {
      if (attrInfo.isClass) {
        for (int i = 0; i < attrInfo.bindings.length; i++) {
          var stopWatcherName = '_stopWatcher${variableName}_$watcherIdx';
          var exp = attrInfo.bindings[i];
          statement.add(
            "$spaces  $stopWatcherName = bind(() => $exp, (e) {\n"
            "$spaces    if (e.oldValue != null && e.oldValue != '') {\n"
            "$spaces      $variableName.classes.remove(e.oldValue);\n"
            "$spaces    }\n"
            "$spaces    if (e.newValue != null && e.newValue != '') {\n"
            "$spaces      $variableName.classes.add(e.newValue);\n"
            "$spaces    }\n"
            "$spaces  });\n");
          watcherIdx++;
        }
      } else {
        statement.add(
          "$spaces  _stopWatcher${variableName}_$watcherIdx ="
          " bind(() => ${attrInfo.boundValue},"
          " (e) {\n$spaces    $variableName.$name = e.newValue;\n"
          "$spaces  });\n");
        watcherIdx++;
      }
    });

    // stop-functions for watchers associated with data-bound content
    if (_info.contentBinding != null) {
      statement.add(
          "$spaces  _stopWatcher${variableName}_$watcherIdx ="
          " bind(() => ${_info.contentBinding},"
          " (e) {\n$spaces    ${variableName}.innerHTML ="
          " ${_info.contentExpression};"
          " });\n");
      watcherIdx++;
    }

    return statement.toString();
  }

  String emitWebComponentRemoved(List<Expression> expressions,
                                 [String indent = null]) {
    String spaces = (indent == null) ? Codegen.spaces(2) : indent;

    StringBuffer statement = new StringBuffer();

    int watcherIdx = 0;

    // Detach event listeners.
    _info.events.forEach((name, eventInfo) {
      var eventName = eventInfo.eventName;
      statement.add(
        "$spaces  $variableName.on.${eventName}.remove($listenerName);\n");
    });

    // Call stop-watcher.
    _info.attributes.forEach((name, attrInfo) {
      for (int i = 0; i < attrInfo.bindings.length; i++) {
        var stopWatcherName = '_stopWatcher${variableName}_$watcherIdx';
        statement.add("$spaces  $stopWatcherName();\n");
        watcherIdx++;
      }
    });

    if (_info.contentBinding != null) {
      var stopWatcherName = '_stopWatcher${variableName}_$watcherIdx';
      statement.add("$spaces  $stopWatcherName();\n");
      watcherIdx++;
    }

    return statement.toString();
  }

  // TODO(sigmund): remove expression argument.
  String emitBoundElementFunction(List<Expression> expressions, int index) {
    // Statements to update attributes associated with expressions.
    StringBuffer statementUpdateAttrs = new StringBuffer();

    StringBuffer statement = new StringBuffer();

    String spaces = Codegen.spaces(2);

    statement.add(
        "$NEW_LINE${spaces}Element templateLine_$index(var e0) {$NEW_LINE");
    statement.add("$spaces  if (e0 == null) {$NEW_LINE");

    // Creation of DOM element.
    bool isTextNode = _elem is HTMLText;
    String createType = isTextNode ? "Text" : "Element.html";
    statement.add("$spaces    e0 = new $createType(\'");
    statement.add(isTextNode ? _buff.toString().trim() : _buff.toString());
    statement.add("\');$NEW_LINE");

    // TODO(terry): Fill in event hookup this is hacky.
    if (_elem.attributes != null) {
      int idx = _info != null && _info.contentBinding != null ? 1 : 0;
      for (var attr in _elem.attributes) {
        if (attr is TemplateAttributeExpression) {
          if (_info.attributes[attr.name] != null) idx++;
          if (_elem.tagTokenId == TokenKind.INPUT_ELEMENT) {
            if (attr.name == "value") {
              // Hook up on keyup.
              statement.add("$spaces    e0.on.keyUp.add(wrap1((_) { model.${
                  attr.value} = e0.value; }));$NEW_LINE");
            } else if (attr.name == "checked") {
              statement.add("$spaces    e0.on.click.add(wrap1((_) { model.${
                  attr.value} = e0.checked; }));$NEW_LINE");
            } else {
              // TODO(terry): Need to handle here with something...
              // data-on-XXXXX would handle on-change .on.change.add(listener);

//              assert(false);
            }
          }

          statementUpdateAttrs.add(
              "$spaces  e0.${attr.name} = inject_$idx();$NEW_LINE");
        }
      }
    }

    statement.add("$spaces  }$NEW_LINE");

    statement.add(statementUpdateAttrs.toString());

    statement.add("$spaces  return e0;$NEW_LINE");
    statement.add("$spaces}$NEW_LINE");

    return statement.toString();
  }

  bool get hasTemplateExpression => _info != null && _info.hasDataBinding;
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
    String spaces = Codegen.spaces(2);

    StringBuffer buff = new StringBuffer();

    buff.add(elemVars.toString());
    buff.add(otherVars.toString());
    buff.add("\n");

    // Build the constructor function.
    if (constructorStmts.length == 0) {
      buff.add("${spaces}$constructorSignature;\n\n");
    } else {
      buff.add("${spaces}$constructorSignature {\n");
      buff.add("${constructorStmts.toString()}");
      buff.add("${spaces}}\n\n");
    }

    // Build the created function.
    buff.add("${spaces}void created(ShadowRoot shadowRoot) {\n");
    // Every created function needs this first line.
    buff.add("$spaces  ${_delegate}root = shadowRoot;\n");
    buff.add(createdStmts.toString());
    buff.add("$spaces}\n\n");

    // Build the inserted function.
    buff.add("${spaces}void inserted() {\n");
    buff.add(insertedStmts.toString());
    buff.add("$spaces}\n\n");

    // Build the removed function.
    buff.add("${spaces}void removed() {\n");
    buff.add(removedStmts.toString());
    buff.add("$spaces}");

    return buff.toString();
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

  // TO-DELETE
  List<Expression> get expressions => _expressions;

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

  bool pushTemplate(int indent, Template template) {
    _cgBlocks.add(new CGBlock.createTemplate(template, indent, processor));
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
  void queueUpFileToProcess(HTMLElement elem) {
    if (elem.tagTokenId == TokenKind.LINK_ELEMENT) {
      bool webComponent = false;
      String href = "";
      // TODO(terry): Consider making HTMLElement attributes a map instead of
      //              a list for faster access.
      for (HTMLAttribute attr in elem.attributes) {
        if (attr.name == 'rel' && attr.value == 'components') {
          webComponent = true;
        }
        if (attr.name == 'href') {
          href = attr.value;
        }
      }
      if (webComponent && !href.isEmpty()) {
        processor.add(href);
      }
    }
  }

  String getAttributeValue(HTMLElement elem, String name) {
    for (HTMLAttribute attr in elem.attributes) {
      if (attr.name.toLowerCase() == name) {
        return attr.value;
      }
    }

    return null;
  }

  final String _SCRIPT_TYPE_ATTR = "type";
  final String _SCRIPT_SRC_ATTR = "src";
  final String _DART_SCRIPT_TYPE = "application/dart";
  emitScript(HTMLElement elem) {
    Expect.isTrue(elem.tagTokenId == TokenKind.SCRIPT_ELEMENT);

    String typeValue = getAttributeValue(elem, _SCRIPT_TYPE_ATTR);
    if (typeValue != null && typeValue == _DART_SCRIPT_TYPE) {
      String includeName = getAttributeValue(elem, _SCRIPT_SRC_ATTR);
      if (includeName != null) {
        _includes.add(includeName);
      } else {
        Expect.isTrue(elem.children.length == 1);
        // This is the code to be emitted with the web component.
        _userCode = elem.children[0].toString();
      }
    } else {
      reportError("tag ignored possibly missing type='application/dart'");
    }
  }

  /**
   * [scopeName] for expression.
   * [parentVarOrIndex] if # it's a local variable if string it's an exposed
   * name (specified by the var attribute) for this element.
   */
  emitElement(var elem,
              [String scopeName = "",
               var parentVarOrIdx = 0,
               bool immediateNestedRepeat = false]) {
    if (elem is Template) {
      Template template = elem;
      emitTemplate(template);
    } else if (elem is HTMLElement) {
      if (!elem.isFragment) {
        add("<${elem.tagName}${elem.attributesToString(false)}>");
      }
      String prevParent = lastVariableName;
      for (var childElem in elem.children) {
        if (childElem is HTMLElement) {
          closeStatement();
          if (childElem.hasVar) {
            emitConstructHtml(childElem, scopeName, prevParent,
              childElem.varName);
          } else {
            emitConstructHtml(childElem, scopeName, prevParent);
          }
          closeStatement();
        } else {
          emitElement(childElem, scopeName, parentVarOrIdx);
        }
      }

      // Close this tag.
      closeStatement();
    } else if (elem is HTMLText) {
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
    } else if (elem is TemplateExpression) {
      emitExpressions(elem, scopeName);
    } else if (elem is TemplateCall) {
      emitCall(elem, parentVarOrIdx);
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
  void emitConstructHtml(var elem,
                         [String scopeName = "",
                          String parentName = "parent",
                          var varIndex = 0,
                          bool immediateNestedRepeat = false]) {
    if (elem is HTMLElement) {
      if (elem is HTMLUnknownElement) {
        HTMLUnknownElement unknownElem = elem;
        if (unknownElem.xTag == "element") {
          _webComponent = true;

          String className = getAttributeValue(unknownElem, "constructor");
          if (className != null) {
            _className = className;
          } else {
            reportError(
                "Web Component class name missing; use constructor attribute");
          }

          String wcName = getAttributeValue(unknownElem, "name");
          if (wcName != null) {
            _webComponentName = wcName;
          } else {
            reportError("Missing name of Web Component use name attribute");
          }

          CGStatement stmt = pushStatement(elem, parentName);
          emitElement(elem, scopeName, stmt.hasGlobalVariable ?
              stmt.variableName : varIndex);
        }
      } else if (elem.tagTokenId == TokenKind.SCRIPT_ELEMENT) {
        // Never emit a script tag.
        emitScript(elem);
      } else if (elem.tagTokenId == TokenKind.LINK_ELEMENT) {
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

  void emitCall(TemplateCall elem, String scopeName) {
    pushStatement(elem, scopeName);
  }

  void emitTemplate(Template elem) {
    if (!pushTemplate(6, elem)) {
      reportError("Error at ${elem}");
    }

    for (var child in elem.children) {
      emitConstructHtml(child, "e0", "templateRoot");
    }
  }
}
