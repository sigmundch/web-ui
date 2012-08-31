The mdv_one sample is an example from the Model-driven Views Experimental Library in
http://code.google.com/p/mdv/.  The example is forms validation at
http://code.google.com/p/mdv/source/browse/use_cases/forms_validation.html.

    # To compile the mdv one template
    tools/run-tool template samples/mdv_one/mdv_one_views.tmpl

The template compiler will create a Dart file name mdv_one_views.tmpl.dart

To run this code, launch [Dartium][] samples/mdv_one/mdv_one_example.html

Please note that this sample is intended to work on all [modern browsers] using the
[dart2js][] compiler. Firefox support is blocked on a
[bug in matchesSelector](http://dartbug.com/4401).

[Dartium]: http://www.dartlang.org/dartium/
[dart2js]: http://www.dartlang.org/docs/dart2js/
[m]: http://www.dartlang.org/support/faq.html#what-browsers-supported
