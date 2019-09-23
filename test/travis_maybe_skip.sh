#!/bin/sh
set -u

INCLUDE_ONLY="\.bib\|\.tex"

git diff-tree --no-commit-id --name-only -r ${TRAVIS_COMMIT} | grep -e ${INCLUDE_ONLY} --quiet
if [ $? -ne 0 ]; then
    travis_terminate 0
    exit 1
fi
# exit 0
set +u
