The hidden example is from the Model-driven Views Experimental Library in
http://code.google.com/p/mdv/.  The example is a variant of
https://code.google.com/p/mdv/source/browse/use_cases/hidden2.html that checks
for two addresses.  This example deviates with the addition of an OK button.
The OK button is enabled or disabled when both the shipping and billing
addresses are known.  Clicking OK displays the address(es) to the console.

    # To compile the MDV hidden template
    tools/run-tool template example/mdv/hidden/hidden.html

The template compiler will create a Dart file name hidden.html.dart

To run this code, launch [Dartium][] example/mdv/hidden/hidden.html.html

Please note that this example is intended to work on all [modern browsers] using
the [dart2js][] compiler. Firefox support is blocked on a
[bug in matchesSelector](http://dartbug.com/4401).

[Dartium]: http://www.dartlang.org/dartium/
[dart2js]: http://www.dartlang.org/docs/dart2js/
[m]: http://www.dartlang.org/support/faq.html#what-browsers-supported
