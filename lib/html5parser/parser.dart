// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * An HTML5 parser written in Dart. Intended for tools and server side usage.
 *
 * Eventually this should parse all valid html documents using the
 * [html5 parsing algorithm][p], although it doesn't do this yet.
 *
 * Also, the parse tree should eventually look like the DOM in the `dart:html`
 * library, and support the subset of operations that make sense without a
 * browser environment.
 *
 * [p]: http://dev.w3.org/html5/spec/parsing.html#parsing
 */
// TODO(jmesserly): we might want a more general name along the lines
// of http://code.google.com/p/html5lib/, because this may eventually support
// more than just parsing.
#library('html5parser');

#import('../../tools/lib/source.dart');
#import('../../tools/lib/world.dart');
#import('htmltree.dart');
#import('tokenizer.dart');
#import('tokenkind.dart');

class TagStack {
  List<TreeNode> _stack;

  TagStack(var elem) : _stack = [] {
    _stack.add(elem);
  }

  void push(var elem) {
    _stack.add(elem);
  }

  TreeNode pop() {
    return _stack.removeLast();
  }

  top() {
    return _stack.last();
  }
}


/**
 * A simple recursive descent parser for HTML.
 */
class Parser {
  Tokenizer tokenizer;

  var fs;                        // If non-null filesystem to read files.

  final SourceFile source;

  Token _previousToken;
  Token _peekToken;

  PrintHandler printHandler;

  Parser(this.source, [int start = 0, this.fs = null]) {
    tokenizer = new Tokenizer(source, true, start);
    _peekToken = tokenizer.next();
    _previousToken = null;
  }

  // Main entry point for parsing an entire HTML file.
  HTMLDocument parse([PrintHandler handler = null]) {
    printHandler = handler;
    var root = new HTMLElement.fragment(
        _makeSpan(_peekToken.start, _peekToken.start));
    return processHTML(root);
  }

  /** Generate an error if [source] has not been completely consumed. */
  void checkEndOfFile() {
    _eat(TokenKind.END_OF_FILE);
  }

  /** Guard to break out of parser when an unexpected end of file is found. */
  // TODO(jimhug): Failure to call this method can lead to inifinite parser
  //   loops.  Consider embracing exceptions for more errors to reduce
  //   the danger here.
  bool isPrematureEndOfFile() {
    if (_maybeEat(TokenKind.END_OF_FILE)) {
      _error('unexpected end of file', _peekToken.span);
      return true;
    } else {
      return false;
    }
  }

  ///////////////////////////////////////////////////////////////////
  // Basic support methods
  ///////////////////////////////////////////////////////////////////
  int _peek() {
    return _peekToken.kind;
  }

  Token _next([bool inTag = true, bool textNodeArea = false]) {
    _previousToken = _peekToken;
    _peekToken = tokenizer.next(inTag, textNodeArea);
    return _previousToken;
  }

  bool _peekKind(int kind) {
    return _peekToken.kind == kind;
  }

  /* Is the next token a legal identifier?  This includes pseudo-keywords. */
  bool _peekIdentifier([String name]) {
    if (_peekToken.kind == TokenKind.IDENTIFIER) {
      return (name != null) ? _peekToken.text == name : true;
    }

    return false;
  }

  bool _maybeEat(int kind) {
    if (_peekToken.kind == kind) {
      _previousToken = _peekToken;
      if (kind == TokenKind.GREATER_THAN) {
        _peekToken = tokenizer.next(false);
      } else {
        _peekToken = tokenizer.next();
      }
      return true;
    } else {
      return false;
    }
  }

  void _eat(int kind) {
    if (!_maybeEat(kind)) {
      _errorExpected(TokenKind.kindToString(kind));
    }
  }

  void _eatSemicolon() {
    _eat(TokenKind.SEMICOLON);
  }

  void _errorExpected(String expected) {
    var tok = _next();
    var message;
    try {
      message = 'expected $expected, but found $tok';
    } catch (e) {
      message = 'parsing error expected $expected';
    }
    _error(message, tok.span);
  }

  void _error(String message, [SourceSpan location=null]) {
    if (location === null) {
      location = _peekToken.span;
    }

    if (printHandler == null) {
      world.fatal(message, location);    // syntax errors are fatal for now
    } else {
      // TODO(terry):  Need common World view for css and template parser.
      //               For now this is how we return errors from CSS - ugh.
      printHandler(message);
    }
  }

  void _warning(String message, [SourceSpan location=null]) {
    if (location === null) {
      location = _peekToken.span;
    }

    if (printHandler == null) {
      world.warning(message, location);
    } else {
      // TODO(terry):  Need common World view for css and template parser.
      //               For now this is how we return errors from CSS - ugh.
      printHandler(message);
    }
  }

  SourceSpan _makeSpan(int start, [int end = -1]) {
    return new SourceSpan(source, start, end == -1 ? _previousToken.end : end);
  }

  ///////////////////////////////////////////////////////////////////
  // Top level productions
  ///////////////////////////////////////////////////////////////////

  /**
   * All tokens are identifiers tokenizer is geared to HTML if identifiers are
   * HTML element or attribute names we need them as an identifier.  Used by
   * template signatures and expressions in ${...}
   */
  Identifier processAsIdentifier() {
    int start = _peekToken.start;

    if (_peekIdentifier()) {
      return identifier();
    } else if (TokenKind.validTagName(_peek())) {
      var tok = _next();
      return new Identifier(TokenKind.tagNameFromTokenId(tok.kind),
        _makeSpan(start));
    }
  }

  static const IF_INSTANTIATE = "if ";

  processHTML(HTMLElement root) {
    assert(root.isFragment);

    // Remember any data-controller attribute specified anywhere.
    String dataController;

    TagStack stack = new TagStack(root);

    int start = _peekToken.start;

    bool done = false;
    while (!done) {
      if (_maybeEat(TokenKind.LESS_THAN)) {
        // Open tag
        start = _peekToken.start;

        int token = _peek();
        bool xTag = token == TokenKind.IDENTIFIER;
        if (TokenKind.validTagName(token) || xTag) {
          bool templateTag = token == TokenKind.TEMPLATE;

          Token tagToken = _next();

          var attrs = processAttributes();

          String varName;
          if (attrs.containsKey('var')) {
            varName = attrs['var'].value;
            attrs.remove('var');
          }

          // Is there a controller to bind to.
          if (attrs.containsKey('data-controller')) {
            dataController = attrs['data-controller'].value;
          }

          int scopeType;     // 1 implies scoped, 2 implies non-scoped element.
          if (_maybeEat(TokenKind.GREATER_THAN)) {
            // Scoped unless the tag is explicitly known as an unscoped tag
            // e.g., <br>.
            scopeType = TokenKind.unscopedTag(tagToken.kind) ? 2 : 1;
          } else if (_maybeEat(TokenKind.END_NO_SCOPE_TAG)) {
            scopeType = 2;
          }
          if (xTag) {
            scopeType = 1;
          }

          if (scopeType > 0) {
            var elem;
            if (templateTag) {
              // Process template
              String instantiate;
              String iterate;
              String isAttr;
              if (attrs.containsKey('instantiate')) {
                instantiate = attrs['instantiate'].value;
                attrs.remove('instantiate');
              }
              if (attrs.containsKey('iterate')) {
                iterate = attrs['iterate'].value;
                attrs.remove('iterate');
              }
              if (attrs.containsKey('is')) {
                isAttr = attrs['is'].value;
                attrs.remove('is');
              }

              if (instantiate != null && iterate != null) {
                _error(
                    'Template must have either iterate or instantiate not both',
                    _makeSpan(start));
              }

              // TODO(terry): Make sure attributes of a template are not
              //              computed expressions.  {{expr}}
              var templAttrs = attrs.getValues();
              var span = _makeSpan(start);
              if (instantiate != null) {
                if (isAttr == Template.IF_COMPONENT) {
                  instantiate = instantiate.trim();
                  if (instantiate.startsWith(IF_INSTANTIATE)) {
                    String condExpr =
                        instantiate.substring(IF_INSTANTIATE.length);
                    elem = new Template.createConditional(templAttrs, condExpr,
                        span);
                  } else {
                    _error('Template conditional instantiate attr missing if.');
                  }
                } else if (isAttr == Template.LIST_COMPONENT) {
                  _error('Template iterate x-list with instantiate attribute.');
                } else {
                  elem = new Template.createInstantiate(templAttrs, instantiate,
                      span);
                }
              } else if (iterate != null) {
                if (isAttr == Template.LIST_COMPONENT) {
                  elem = new Template.createIterate(templAttrs, iterate, span);
                } else {
                  _error('Template conditional x-if with iterate attribute.');
                }
              } else {
                elem = new Template(templAttrs, span);
              }
            } else if (!xTag) {
              elem = new HTMLElement.createAttributes(tagToken.kind,
                                                attrs.getValues(),
                                                varName,
                                                _makeSpan(start));
            } else {
              // XTag
              elem = new HTMLUnknownElement.attributes(tagToken.text,
                  attrs.getValues(),
                  varName,
                  _makeSpan(start));
            }

            stack.top().add(elem);

            if (scopeType == 1) {
              // Maybe more nested tags/text?
              stack.push(elem);
            }
          }
        } else {
          // Close tag
          _eat(TokenKind.SLASH);
          bool nextIsXTag = _peek() == TokenKind.IDENTIFIER;
          if (TokenKind.validTagName(_peek()) || nextIsXTag) {
            Token tagToken = _next();

            _eat(TokenKind.GREATER_THAN);

            HTMLElement elem = stack.pop();
            if (!elem.isFragment) {

              if (!elem.isXTag) {
                if (elem.tagTokenId != tagToken.kind) {
                  _error('Tag doesn\'t match expected </${elem.tagName
                      }> got </${
                      TokenKind.tagNameFromTokenId(tagToken.kind)}>');
                }
              } else {
                if (elem.tagName != tagToken.text) {
                  _error('XTag doesn\'t match expected </${elem.tagName
                      }> got </${tagToken.text}>');
                }
              }
            } else {
              // Too many end tags.
              _error('Too many end tags at </${
                  TokenKind.tagNameFromTokenId(tagToken.kind)}>');
            }
          }
        }
      } else {
        // Any text or expression nodes?
        var nodes = processTextNodes();
        if (nodes.length > 0) {
          assert(stack.top() != null);
          for (var node in nodes) {
            stack.top().add(node);
          }
        } else {
          break;
        }
      }
    }

    // TODO(terry): Need to enable this check.
/*
    if (elems.children.length != 1) {
      print("ERROR: No closing end-tag for elems ${elems[elems.length - 1]}");
    }
*/

    var docChildren = new List<TreeNode>();
    docChildren.add(stack.pop());
    return new HTMLDocument(dataController, docChildren, _makeSpan(start));
  }

  /* Map is used so only last unique attribute name is remembered and to quickly
   * find the var attribute.
   */
  Map<String, HTMLAttribute> processAttributes() {
    var attrs = <HTMLAttribute>{};

    int start = _peekToken.start;
    String elemName;
    while (_peekIdentifier() ||
           (elemName = TokenKind.tagNameFromTokenId(_peek())) != null) {
      var attrName;
      if (elemName == null) {
        attrName = identifier();
      } else {
        attrName = new Identifier(elemName, _makeSpan(start));
        _next();
      }

      var attrValue;

      // Attribute value?
      if (_peek() == TokenKind.ATTR_VALUE) {
        var tok = _next();
        if (tok is LiteralToken) {
          LiteralToken litTok = tok;
          attrValue = new StringValue(litTok.value, _makeSpan(litTok.start));
        }
        attrs[attrName.dynamic.name] = new HTMLAttribute(attrName.toString(),
                                                 attrValue.toString(),
                                                 _makeSpan(start));
      } else if (_peek() == TokenKind.EXPRESSION) {
        var tok = _next();
        if (tok is LiteralToken) {
          LiteralToken litTok = tok;
          attrValue = new StringValue(litTok.value, _makeSpan(litTok.start));
        }
        attrs[attrName.dynamic.name] =
            new TemplateAttributeExpression(attrName.toString(),
          attrValue.toString(),
          _makeSpan(start));
      }


      start = _peekToken.start;
      elemName = null;
    }

    return attrs;
  }

  identifier() {
    var tok = _next();
    if (tok.kind != TokenKind.IDENTIFIER) {
      _error('expected identifier, but found $tok', tok.span);
    }

    return new Identifier(tok.text, _makeSpan(tok.start));
  }

  List<TreeNode> processTextNodes() {
    // May contain TemplateText and TemplateExpression.
    List<TreeNode> nodes = [];

    int start = _peekToken.start;
    bool inExpression = false;
    StringBuffer stringValue = new StringBuffer();

    // Any text chars between close of tag and text node?
    if (_previousToken.kind == TokenKind.GREATER_THAN) {
      // If the next token is } could be the close template token.  If user
      // needs } as token in text node use the entity &125;
      // TODO(terry): Probably need a &RCURLY entity instead of 125.
      if (_peek() == TokenKind.ERROR) {
        // Backup, just past previous token, & rescan we're outside of the tag.
        tokenizer.index = _previousToken.end;
        _next(false);
      } else if (_peek() != TokenKind.RBRACE) {
        // Yes, grab the chars after the >
        stringValue.add(_previousToken.source.text.substring(
            this._previousToken.end, this._peekToken.start));
      }
    }

    // Gobble up everything until we hit <
    while (_peek() != TokenKind.LESS_THAN && _peek() != TokenKind.END_OF_FILE) {
      var tok = _next(false, true);
      // Expression?
      if (tok.kind == TokenKind.EXPRESSION) {
        if (stringValue.length > 0) {
          // We have a real text node create the text node.
          nodes.add(new HTMLText(stringValue.toString(), _makeSpan(start)));
          stringValue = new StringBuffer();
          start = _peekToken.start;
        }
        LiteralToken litTok = tok;
        nodes.add(new TemplateExpression(litTok.value, _makeSpan(start)));
        stringValue = new StringBuffer();
        start = _peekToken.start;
      } else if (tok.kind == TokenKind.TEXT_NODE) {
        stringValue.add(tok.text);
      } else {
        // Only save the the contents between ${ and }
        stringValue.add(tok.text);
      }
    }

    if (stringValue.length > 0) {
      nodes.add(new HTMLText(stringValue.toString(), _makeSpan(start)));
    }

    return nodes;
  }

}
