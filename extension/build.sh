#!/bin/bash
# Extensions can't handle symlinks so we have to copy files to make everything
# work.
# TODO(jacobr): use "pub deploy" in the future instead of performing a copy.

# Run from the script's directory
cd $( dirname "${BASH_SOURCE[0]}" )
# Bail on non-zero error code
set -e

# Remove old output, if any
if [ -d "output" ]; then
  rm -r output
fi
mkdir output
cp -r ../bin output/
rm output/bin/packages
cp -L -r ../packages output/bin/
cp -r ../lib output/
cp *.html *.js *.json output/
