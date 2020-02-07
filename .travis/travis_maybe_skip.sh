#!/bin/sh
set -u

INCLUDE_ONLY="\.bib\|\.tex\|travis\|optbib2html\|deploy"

# Use -m so that merge commits are also considered
echo git diff --raw -c --no-commit-id --name-only ${TRAVIS_COMMIT_RANGE}
git diff --raw -c --no-commit-id --name-only ${TRAVIS_COMMIT_RANGE} | grep -e ${INCLUDE_ONLY} --quiet
if [ $? -ne 0 ]; then
    exit 1
fi
set +u
exit 0
