# changelog

This file contains highlights of what changes on each version of the web
components package. This file is normally updated whenever we push a new version
to pub.

## Unreleased

  * Two-way bindings changes:
    * New syntax: `bind-attribute="dartAssignableValue"`, `data-bind` is
      deprecated
    * Support for radio buttons
    * Support for valueAsDate and valueAsNumber
    * Better detection of error conditions, like duplicate value attributes.
  * Bug fixes:
    * Make sure dartium extension uses the latest dart.js

## Pub version 0.2.7 - Nov 26 (SDK 15355)

  * New syntax for inline event handlers: `on-click="increment($event)"` instead
    of `data-action="click:increment"`
  * Added new explainer examples
  * Bug fixes:
      * Support for querying for elements from main()
      * Recursive imports between components
      * Warnings are emitted (previously they were generated but not printed)
  * Updated dartium extension

## Pub version 0.2.6+1 - 16 Nov 2012

  * Name mangling turned off if --out is specified
  * Support for `<select>` in data-bind

## Pub version 0.2.5+5

  * Bug fix: adds missing id on elements that we query in generated code

## Pub version 0.2.5+4

  * Bug fix: additional fixes for symlinks in windows

## Pub version 0.2.5+3

  * Fixes symlinks for windows
  * Support for composition and extension
  * Support for list and spaces in bindings of class attribtues
  * Simpliffications in generated code
  * Allow text bindings and fragments in conditions an iterations
  * Support text nodes and fragments at the top level of components

See git version tags for older changes.