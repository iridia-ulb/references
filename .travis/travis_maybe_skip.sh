#!/bin/sh
set -u
set +e
INCLUDE_ONLY="\.bib\|\.tex\|travis\|optbib2html\|deploy"
# Use -m so that merge commits are also considered
echo git diff --raw -c --no-commit-id --name-only ${TRAVIS_COMMIT_RANGE}
# If this command fails, we should exit 0 so we do not skip
git diff --raw -c --no-commit-id --name-only ${TRAVIS_COMMIT_RANGE}
if [ $? -eq 0 ]; then
    git diff --raw -c --no-commit-id --name-only ${TRAVIS_COMMIT_RANGE} | grep -e ${INCLUDE_ONLY} --quiet
    if [ $? -ne 0 ]; then
        exit 1
    fi
fi
set +u
set -e
exit 0
