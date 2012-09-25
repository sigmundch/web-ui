TodoMVC sample application written with web-components and templates bound to
models. You can run it out of the box on Dartium using dart:mirrors.
That means you can edit it and refresh and see it automatically update.

To run this code, launch [Dartium][] with these flags:

    --enable-experimental-webkit-features --allow-file-access-from-files --enable-devtools-experiments

Then open `main.html`.

Please note that this sample is intended to work on all [modern browsers][m] but
at the moment we rely on features like scoped styles and shadow DOM that have
only been implemented in Chrome. The `output` verion will run on these browsers
using the [dart2js][] compiler.

[Dartium]: http://www.dartlang.org/dartium/
[dart2js]: http://www.dartlang.org/docs/dart2js/
[m]: http://www.dartlang.org/support/faq.html#what-browsers-supported
