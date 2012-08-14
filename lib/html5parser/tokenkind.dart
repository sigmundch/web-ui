// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('tokenkind');

// TODO(terry): Cleanup to remove all tokens that were for Dart style
//              expressions only tokens should be for HTML and MDV.
// TODO(terry): Need to be consistent with tokens either they're ASCII tokens
//              e.g., ASTERISK or they're CSS e.g., PSEUDO, COMBINATOR_*.
class TokenKind {
  // Common shared tokens used in TokenizerBase.
  static final int UNUSED = 0;                  // Unused place holder...
  static final int END_OF_FILE = 1;
  static final int LPAREN = 2;                  // (
  static final int RPAREN = 3;                  // )
  static final int LBRACK = 4;                  // [
  static final int RBRACK = 5;                  // ]
  static final int LBRACE = 6;                  // {
  static final int RBRACE = 7;                  // }
  static final int DOT = 8;                     // .
  static final int SEMICOLON = 9;               // ;
  static final int SPACE = 10;                  // space character
  static final int TAB = 11;                    // \t
  static final int NEWLINE = 12;                // \n
  static final int RETURN = 13;                 // \r
  static final int COMMA = 14;                  // ,

  // Unique tokens.
  static final int LESS_THAN = 15;              // <
  static final int GREATER_THAN = 16;           // >
  static final int SLASH = 17;                  // /
  static final int DOLLAR = 18;                 // $
  static final int HASH = 19;                   // #
  static final int MINUS = 20;                  // -
  static final int EQUAL = 21;                  // =
  static final int DOUBLE_QUOTE = 22;           // "
  static final int SINGLE_QUOTE = 23;           // '
  static final int ASTERISK = 24;               // *

  // WARNING: END_TOKENS must be 1 greater than the last token above (last
  //          character in our list).  Also add to kindToString function and the
  //          constructor for TokenKind.

  static final int END_TOKENS = 25;             // Marker for last token in list

  // Synthesized tokens:

  static final int END_NO_SCOPE_TAG = 50;       // />
  static final int START_EXPRESSION = 51;       // {{
  static final int END_EXPRESSION = 52;         // }}
  static final int EXPRESSION = 53;             // expression between {{ and }}

  /** [TokenKind] representing integer tokens. */
  static final int INTEGER = 60;                // TODO(terry): must match base

  /** [TokenKind] representing hex integer tokens. */
  static final int HEX_INTEGER = 61;          // TODO(terry): must match base

  /** [TokenKind] representing double tokens. */
  static final int DOUBLE = 62;                 // TODO(terry): must match base

  /** [TokenKind] representing whitespace tokens. */
  static final int WHITESPACE = 63;             // TODO(terry): must match base

  /** [TokenKind] representing comment tokens. */
  static final int COMMENT = 64;                // TODO(terry): must match base

  /** [TokenKind] representing error tokens. */
  static final int ERROR = 65;                  // TODO(terry): must match base

  /** [TokenKind] representing incomplete string tokens. */
  static final int INCOMPLETE_STRING = 66;      // TODO(terry): must match base

  /** [TokenKind] representing incomplete comment tokens. */
  static final int INCOMPLETE_COMMENT = 67;     // TODO(terry): must match base

  // Synthesized Tokens (no character associated with TOKEN).
  // TODO(terry): Possible common names used by both Dart and CSS tokenizers.
  static final int ATTR_VALUE = 500;
  static final int NUMBER = 502;
  static final int HEX_NUMBER = 503;
  static final int HTML_COMMENT = 504;          // <!--
  static final int IDENTIFIER = 511;
  static final int STRING = 512;
  static final int STRING_PART = 513;

  static final int TEMPLATE_KEYWORD = 595;      // template keyword

  // Elements
  /* START_HTML_ELEMENT is first valid element tag name
   * END_HTML_ELEMENT is the last valid element tag name
   *
   */
  static final int START_HTML_ELEMENT = 600;      // First valid tag name.
  static final int A_ELEMENT = 600;
  static final int ABBR_ELEMENT = 601;
  static final int ACRONYM_ELEMENT = 602;
  static final int ADDRESS_ELEMENT = 603;
  static final int APPLET_ELEMENT = 604;
  static final int AREA_ELEMENT = 605;
  static final int B_ELEMENT = 606;
  static final int BASE_ELEMENT = 607;
  static final int BASEFONT_ELEMENT = 608;
  static final int BDO_ELEMENT = 609;
  static final int BIG_ELEMENT = 610;
  static final int BLOCKQUOTE_ELEMENT = 611;
  static final int BODY_ELEMENT = 612;
  static final int BR_ELEMENT = 613;
  static final int BUTTON_ELEMENT = 614;
  static final int CAPTION_ELEMENT = 615;
  static final int CENTER_ELEMENT = 616;
  static final int CITE_ELEMENT = 617;
  static final int CODE_ELEMENT = 618;
  static final int COL_ELEMENT = 619;
  static final int COLGROUP_ELEMENT = 620;
  static final int DD_ELEMENT = 621;
  static final int DEL_ELEMENT = 622;
  static final int DFN_ELEMENT = 623;
  static final int DIR_ELEMENT = 624;
  static final int DIV_ELEMENT = 625;
  static final int DL_ELEMENT = 626;
  static final int DT_ELEMENT = 627;
  static final int EM_ELEMENT = 628;
  static final int FIELDSET_ELEMENT = 629;
  static final int FONT_ELEMENT = 630;
  static final int FORM_ELEMENT = 631;
  static final int FRAME_ELEMENT = 632;
  static final int FRAMESET_ELEMENT = 633;
  static final int H1_ELEMENT = 634;
  static final int H2_ELEMENT = 635;
  static final int H3_ELEMENT = 636;
  static final int H4_ELEMENT = 637;
  static final int H5_ELEMENT = 638;
  static final int H6_ELEMENT = 639;
  static final int HEAD_ELEMENT = 640;
  static final int HR_ELEMENT = 641;
  static final int HTML_ELEMENT = 642;
  static final int I_ELEMENT = 643;
  static final int IFRAME_ELEMENT = 644;
  static final int IMG_ELEMENT = 645;
  static final int INPUT_ELEMENT = 646;
  static final int INS_ELEMENT = 647;
  static final int ISINDEX_ELEMENT = 648;
  static final int KBD_ELEMENT = 649;
  static final int LABEL_ELEMENT = 650;
  static final int LEGEND_ELEMENT = 651;
  static final int LI_ELEMENT = 652;
  static final int LINK_ELEMENT = 653;
  static final int MAP_ELEMENT = 654;
  static final int MENU_ELEMENT = 645;
  static final int META_ELEMENT = 656;
  static final int NOFRAMES_ELEMENT = 657;
  static final int NOSCRIPT_ELEMENT = 658;
  static final int OBJECT_ELEMENT = 659;
  static final int OL_ELEMENT = 660;
  static final int OPTGROUP_ELEMENT = 661;
  static final int OPTION_ELEMENT = 662;
  static final int P_ELEMENT = 663;
  static final int PARAM_ELEMENT = 664;
  static final int PRE_ELEMENT = 665;
  static final int Q_ELEMENT = 666;
  static final int S_ELEMENT = 667;
  static final int SAMP_ELEMENT = 668;
  static final int SCRIPT_ELEMENT = 669;
  static final int SELECT_ELEMENT = 670;
  static final int SMALL_ELEMENT = 671;
  static final int SPAN_ELEMENT = 672;
  static final int STRIKE_ELEMENT = 673;
  static final int STRONG_ELEMENT = 674;
  static final int STYLE_ELEMENT = 675;
  static final int SUB_ELEMENT = 676;
  static final int SUP_ELEMENT = 677;
  static final int TABLE_ELEMENT = 678;
  static final int TBODY_ELEMENT = 679;
  static final int TD_ELEMENT = 680;
  static final int TEMPLATE = 681;
  static final int TEXTAREA_ELEMENT = 682;
  static final int TFOOT_ELEMENT = 683;
  static final int TH_ELEMENT = 684;
  static final int THEAD_ELEMENT = 685;
  static final int TITLE_ELEMENT = 686;
  static final int TR_ELEMENT = 687;
  static final int TT_ELEMENT = 688;
  static final int U_ELEMENT = 689;
  static final int UL_ELEMENT = 690;
  static final int VAR_ELEMENT = 691;
  static final int END_HTML_ELEMENT = VAR_ELEMENT;    // Last valid tag name.

  static bool validTagName(int tokId) {
    return tokId >= START_HTML_ELEMENT && tokId <= END_HTML_ELEMENT;
  }

  // tag values starting with a minus sign implies tag can be unscoped e.g.,
  // <br> is valid without <br></br> or <br/>
  static final List<String> _ELEMENTS = const [
    'a',
    'abbr',
    'acronym',
    'address',
    'applet',
    'area',
    'b',
    'base',
    'basefont',
    'bdo',
    'big',
    'blockquote',
    'body',
    'br',
    'button',
    'caption',
    'center',
    'cite',
    'code',
    'col',
    'colgroup',
    'dd',
    'del',
    'dfn',
    'dir',
    'div',
    'dl',
    'dt',
    'em',
    'fieldset',
    'font',
    'form',
    'frame',
    'frameset',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'head',
    'hr',
    'html',
    'i',
    'iframe',
    'img',
    'input',
    'ins',
    'isindex',
    'kbd',
    'label',
    'legend',
    'li',
    'link',
    'map',
    'menu',
    'meta',
    'noframes',
    'noscript',
    'object',
    'ol',
    'optgroup',
    'option',
    'p',
    'param',
    'pre',
    'q',
    's',
    'samp',
    'script',
    'select',
    'small',
    'span',
    'strike',
    'strong',
    'style',
    'sub',
    'sup',
    'table',
    'tbody',
    'td',
    'template',
    'textarea',
    'tfoot',
    'th',
    'thead',
    'title',
    'tr',
    'tt',
    'u',
    'ul',
    'var',
  ];

  // Some more constants:
  static final int ASCII_UPPER_A = 65;    // ASCII value for uppercase A
  static final int ASCII_UPPER_Z = 90;    // ASCII value for uppercase Z

  /**
   * Return the token that matches the element ident found.
   */
  static int matchElements(String text, int offset, int length) {
    // TODO(jmesserly): this isn't very efficient. It'd be better to handle
    // these in the main tokenizer loop by switching on charcodes.
    var search = text.substring(offset, length + offset).toLowerCase();
    var match = _ELEMENTS.indexOf(search);
    if (match < 0) return match;
    return match + START_HTML_ELEMENT;
  }

  static String tagNameFromTokenId(int tagTokenId) {
    if (validTagName(tagTokenId)) {
      return _ELEMENTS[tagTokenId - START_HTML_ELEMENT];
    }
    return null;
  }

  static bool unscopedTag(int tokenId) {
    return tokenId == BR_ELEMENT || tokenId == INPUT_ELEMENT;
  }

  static String kindToString(int kind) {
    switch(kind) {
      case TokenKind.UNUSED: return "ERROR";
      case TokenKind.END_OF_FILE: return "end of file";
      case TokenKind.LPAREN: return "(";
      case TokenKind.RPAREN: return ")";
      case TokenKind.LBRACK: return "[";
      case TokenKind.RBRACK: return "]";
      case TokenKind.LBRACE: return "{";
      case TokenKind.RBRACE: return "}";
      case TokenKind.DOT: return ".";
      case TokenKind.SEMICOLON: return ";";
      case TokenKind.SPACE: return " ";
      case TokenKind.TAB: return "\t";
      case TokenKind.NEWLINE: return "\n";
      case TokenKind.RETURN: return "\r";
      case TokenKind.COMMA: return ",";
      case TokenKind.LESS_THAN: return "<";
      case TokenKind.GREATER_THAN: return ">";
      case TokenKind.SLASH: return "/";
      case TokenKind.DOLLAR: return "\$";
      case TokenKind.HASH: return "#";
      case TokenKind.MINUS: return '-';
      case TokenKind.EQUAL: return '=';
      case TokenKind.DOUBLE_QUOTE: return '"';
      case TokenKind.SINGLE_QUOTE: return "'";
      case TokenKind.ASTERISK: return "*";
      case TokenKind.END_NO_SCOPE_TAG: return '/>';
      case TokenKind.START_EXPRESSION: return '{{';
      case TokenKind.END_EXPRESSION: return '}}';
      case TokenKind.EXPRESSION: return '{{expr}}';
      case TokenKind.INTEGER: return 'integer';
      case TokenKind.DOUBLE: return 'double';
      case TokenKind.WHITESPACE: return 'whitespace';
      case TokenKind.COMMENT: return 'comment';
      case TokenKind.ERROR: return 'error';
      case TokenKind.INCOMPLETE_STRING : return 'incomplete string';
      case TokenKind.INCOMPLETE_COMMENT: return 'incomplete comment';
      case TokenKind.ATTR_VALUE: return 'attribute value';
      case TokenKind.NUMBER: return 'number';
      case TokenKind.HEX_NUMBER: return 'hex number';
      case TokenKind.HTML_COMMENT: return 'HTML comment <!-- -->';
      case TokenKind.IDENTIFIER: return 'identifier';
      case TokenKind.STRING: return 'string';
      case TokenKind.STRING_PART: return 'string part';
      case TokenKind.TEMPLATE_KEYWORD: return 'template';
      default:
        throw "Unknown TOKEN";
    }
  }
}

// Note: these names should match TokenKind names
// TODO(jmesserly): we could just make these values match TokenKind, then
// we'd only need one enum.
class TokenChar {
  static final int UNUSED = -1;
  static final int END_OF_FILE = 0;
  static final int LPAREN = 0x28; // "(".charCodeAt(0)
  static final int RPAREN = 0x29; // ")".charCodeAt(0)
  static final int LBRACE = 0x7b; // "{".charCodeAt(0)
  static final int RBRACE = 0x7d; // "}".charCodeAt(0)
  static final int SPACE = 0x20; // " ".charCodeAt(0)
  static final int TAB = 0x9; // "\t".charCodeAt(0)
  static final int NEWLINE = 0xa; // "\n".charCodeAt(0)
  static final int RETURN = 0xd; // "\r".charCodeAt(0)
  static final int COMMA = 0x2c; // ",".charCodeAt(0)
  static final int LESS_THAN = 0x3c; // "<".charCodeAt(0)
  static final int GREATER_THAN = 0x3e; // ">".charCodeAt(0)
  static final int SLASH = 0x2f; // "/".charCodeAt(0)
  static final int MINUS = 0x2d; // "-".charCodeAt(0)
  static final int EQUAL = 0x3d; // "=".charCodeAt(0)
  static final int DOUBLE_QUOTE = 0x22; // '"'.charCodeAt(0)
  static final int SINGLE_QUOTE = 0x27; // "'".charCodeAt(0)
  static final int ASTERISK = 0x2a; // "*".charCodeAt(0)
}


class NoElementMatchException implements Exception {
  String _tagName;
  NoElementMatchException(this._tagName);

  String get name() => _tagName;
}
