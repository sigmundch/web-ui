#!/bin/bash
set -e

DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )

if [[ ($DART_SDK == "") ]]; then
  echo 'DART_SDK not set, using `which dart` to guess path'
  export DART_SDK=$( cd $( dirname `which dart` )/.. && pwd )
  echo "Found SDK at $DART_SDK"
fi

# TODO(jmesserly): this should be a package on Pub, then we can delete these
# shell script shenanigans.
echo "library compile_mirrors; export '$DART_SDK/pkg/dartdoc/lib/mirrors.dart';" > $DIR/compile_mirrors.dart
dart --checked $DIR/gen_html_setters.dart
