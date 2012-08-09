Dart Web Components
===================

Dart Web Components let you build web apps as if you had a browser from the
future. You can use the cool new web technologies like [Web Components][wc],
[Model Driven Views][mdv] and [Dart][d] today. Build apps easily using HTML as
your template language, express your application's components in HTML, and
synchronize your data automatically between Dart and your components.

We believe that:

- Web Components are on their way, we should start using them now.
- Cool new features should be made available to [modern browsers][mb] that
  haven't yet implemented them.
- Write/Reload is just as important as write/compile/minimize/ship.
- Working in open source is the way to go.
- Developers from all backgrounds should be building awesome modern web apps.

This library is under construction. More coming soon!


Running Tests
-------------

Dependencies are installed using the [Pub Package Manager][pub].

    pub install

    # Run command line tests
    #export DART_SDK=path/to/dart/sdk
    tests/run.sh

    # Run browser tests
    export DART_PACKAGE_ROOT=file://`pwd`/packages
    dartium --allow-file-access-from-files browser_tests.html

You can run `browser_tests.html` from [Dartium][Dartium] launched with
`--allow-file-access-from-files` or from a Dart enabled [DumpRenderTree][drt],
which can be downloaded prebuilt for [Ubuntu Lucid][drtlucid],
[Windows][drtwin], or [Mac][drtmac]. You can also build these from the
[Dartium and DRT sources][drtsrc].

    # To compile the mdv one template example
    tools/tool template samples/mdv_one/mdv_one/views.tmpl

[wc]: http://dvcs.w3.org/hg/webcomponents/raw-file/tip/explainer/index.html
[mdv]: http://code.google.com/p/mdv/
[d]: http://www.dartlang.org
[mb]: http://www.dartlang.org/support/faq.html#what-browsers-supported
[pub]: http://www.dartlang.org/docs/pub-package-manager/
