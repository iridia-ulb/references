#!/bin/sh
set -u
set -e
MESSAGE=$(git log --format=%B -n 1 $TRAVIS_COMMIT)
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"
git add testbib.pdf
git commit --message "testbib.pdf: Regenerate (build: $TRAVIS_BUILD_NUMBER)."
git remote -v
git remote add origin "https://${GH_TOKEN}@${GH_REPO}" > /dev/null 2>&1
git push  --quiet --set-upstream origin master


