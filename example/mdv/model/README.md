The model example is from the Model-driven Views Experimental Library in
http://code.google.com/p/mdv/.  The example is a variant of forms validation at
http://code.google.com/p/mdv/source/browse/use_cases/forms_validation.html.  The
difference is that a specific model class is defined outside of main is used.

    # To compile the MDV forms_validation template
    tools/run-tool template example/mdv/model/main.html

The template compiler will create a Dart file name main.html.dart

To run this code, launch [Dartium][] example/mdv/model/main.html.html

Please note that this example is intended to work on all [modern browsers] using
the [dart2js][] compiler. Firefox support is blocked on a
[bug in matchesSelector](http://dartbug.com/4401).

[Dartium]: http://www.dartlang.org/dartium/
[dart2js]: http://www.dartlang.org/docs/dart2js/
[m]: http://www.dartlang.org/support/faq.html#what-browsers-supported
