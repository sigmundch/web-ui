#!/bin/bash
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script to run all tests in the webcomponents package.
#
# To run these tests automatically on every push request do the following:
#   > cd <git-home> # stand on your git home directory containing this repo.
#   > ln -s $PWD/tests/run.sh .git/hooks/pre-receive
#
# For this script to run correctly, you need to have either a SDK installation,
# and set a couple environment variables:
#   > export DART_SDK=<SDK location>
#
# If you already have a dart_lang checkout, you can build the SDK directly.

DART=$DART_SDK/bin/dart

for test in tests/*_test.dart; do
  $DART --package-root=packages/ $test
done
