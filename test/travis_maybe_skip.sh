#!/bin/sh
set -u

INCLUDE_ONLY="\.bib\|\.tex\|travis\|optbib2html\|deploy"

# Use -m so that merge commits are also considered
git diff-tree -m  --no-commit-id --name-only -r ${TRAVIS_COMMIT} | grep -e ${INCLUDE_ONLY} --quiet
if [ $? -ne 0 ]; then
    travis_terminate 0
    exit 1
fi
# exit 0
set +u
