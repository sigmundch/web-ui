#!/bin/bash
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# TODO(sigmund): replace with a real test runner

# bail on error
set -e

# print commands executed by this script
# set -x

DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
DART_FLAGS="--enable-type-checks --enable-asserts"

for test in $DIR/*_test.dart; do
  dart $DART_FLAGS $test
done

for input in $DIR/data/input/*_test.html; do
  echo -e "\nTesting $input:"
  FILENAME=`basename $input.html`
  dart $DART_FLAGS bin/dwc.dart $input $DIR/data/output/
  DUMP="$DIR/data/output/$FILENAME.txt"
  EXPECTATION="$DIR/data/expected/$FILENAME.txt"
  DART_PACKAGE_ROOT="file://$DIR/packages/" \
      DumpRenderTree $DIR/data/output/$FILENAME > $DUMP

  # use a standard diff, if they are not identical, format the diff nicely to
  # see what's the error, then return an error code and exit.
  diff -q -s $EXPECTATION $DUMP || (\
    diff -t -y $EXPECTATION $DUMP | \
      sed -e "s/\(^.\{63\}\)\(\s[<]\(\s\|$\)\)\(.*\)/[31m\1[33m\2[32m\4[0m/" |\
      sed -e "s/\(^.\{63\}\)\(\s[|]\(\s\|$\)\)\(.*\)/[33m\1[33m\2[33m\4[0m/" |\
      sed -e "s/\(^.\{63\}\)\(\s[>]\(\s\|$\)\)\(.*\)/[31m\1[33m\2[32m\4[0m/"; 1)

done
