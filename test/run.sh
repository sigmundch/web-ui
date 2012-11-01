#!/bin/bash
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Usage: call directly in the commandline as test/run.sh ensuring that you have
# both 'dart' and 'DumpRenderTree' in your path. Filter tests by passing a
# pattern as an argument to this script.

# TODO(sigmund): replace with a real test runner

# bail on error
set -e

# print commands executed by this script
# set -x

DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
DART_FLAGS="--checked"
TEST_PATTERN=$1

function show_diff {
  echo -en "[33mExpected[0m"
  echo -n "                                                           "
  echo -e "[32mOutput[0m"
  diff -t -y $1 $2 | \
    sed -e "s/\(^.\{63\}\)\(\s[<]\(\s\|$\)\)\(.*\)/[31m\1[33m\2[32m\4[0m/" |\
    sed -e "s/\(^.\{63\}\)\(\s[|]\(\s\|$\)\)\(.*\)/[33m\1[33m\2[33m\4[0m/" |\
    sed -e "s/\(^.\{63\}\)\(\s[>]\(\s\|$\)\)\(.*\)/[31m\1[33m\2[32m\4[0m/"
  return 1
}

function update {
  read -p "Would you like to update the expectations? [y/N]: " answer
  if [[ $answer == 'y' || $answer == 'Y' ]]; then
    cp $2 $1
    return 0
  fi
  return 1
}

function pass {
  echo -e "[32mPASS[0m"
}

function compare {
  # use a standard diff, if they are not identical, format the diff nicely to
  # see what's the error and prompt to see if they wish to update it. If they
  # do, continue running more tests.
  diff -q $1 $2 && pass || show_diff $1 $2 || update $1 $2
}

if [[ ($TEST_PATTERN == "") ]]; then
  # Note: dart_analyzer needs to be run from the root directory for proper path
  # canonicalization.
  pushd $DIR/..
  echo Analyzing compiler for warnings or type errors
  dart_analyzer bin/dwc.dart \
    --work analyzer_out
  rm -r analyzer_out
  popd
fi

# First clear the output folder. Otherwise we can miss bugs when we fail to
# generate a file.
if [[ -d $DIR/data/output ]]; then
  rm -rf $DIR/data/output/*
  ln -s $DIR/packages $DIR/data/output/packages
fi

pushd $DIR
dart $DART_FLAGS run_all.dart $TEST_PATTERN
popd

# TODO(jmesserly): bash and dart regexp might not be 100% the same. Ideally we
# could do all the heavy lifting in Dart code, and keep this script as a thin
# wrapper that sets `--enable-type-checks --enable-asserts`
for input in $DIR/data/input/*_test.html; do
  if [[ ($TEST_PATTERN == "") || ($input =~ $TEST_PATTERN) ]]; then
    FILENAME=`basename $input.html`
    echo -e -n "Testing $FILENAME "
    DUMP="$DIR/data/output/$FILENAME.txt"
    EXPECTATION="$DIR/data/expected/$FILENAME.txt"
    DART_PACKAGE_ROOT="file://$DIR/packages/" \
        DumpRenderTree $DIR/data/output/_$FILENAME > $DUMP

    compare $EXPECTATION $DUMP
  fi
done

# Run Dart analyzer to check that we're generating warning clean code.
OUT_PATTERN="$DIR/data/output/*$TEST_PATTERN*_bootstrap.dart"
if [[ `ls $OUT_PATTERN 2>/dev/null` != "" ]]; then
  echo -e "\n Analyzing generated code for warnings or type errors."
  ls $OUT_PATTERN | dart_analyzer --fatal-warnings --fatal-type-errors \
    --work $DIR/data/output/analyzer/ -batch
fi

echo All tests pass.
