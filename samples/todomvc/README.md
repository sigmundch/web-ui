TodoMVC sample application written with web-components and templates bound to
models. You can run it out of the box on Dartium using dart:mirrors.
That means you can edit it and refresh and see it automatically update.

To run this code, launch [Dartium][] with these flags:

    --enable-shadow-dom --enable-scoped-style --allow-file-access-from-files --enable-devtools-experiments
    
Then open `main.html`

Please note that this sample is intended to work on all [modern browsers][m] but
at the moment we rely on features like scoped styles and shadow DOM that have
only been implemented in Chrome. The `output` verion will run in Chrome using
the [dart2js][] compiler. Firefox support is blocked on a
[bug in matchesSelector](http://dartbug.com/4401). Support for other browsers is
blocked on support for
[DOM mutation observers](http://www.w3.org/TR/dom/#mutation-observers).

[Dartium]: http://www.dartlang.org/dartium/
[dart2js]: http://www.dartlang.org/docs/dart2js/
[m]: http://www.dartlang.org/support/faq.html#what-browsers-supported

