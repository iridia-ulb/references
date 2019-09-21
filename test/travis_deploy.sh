#!/bin/sh
set -u
set -e
MESSAGE=$(git log --format=%B -n 1 $TRAVIS_COMMIT)
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"
#git checkout -b master
git add testbib.pdf
git st
git commit --message "testbib.pdf: Regenerate (build: $TRAVIS_BUILD_NUMBER)."
#git remote add origin-pages https://${GH_TOKEN}@github.com/MVSE-outreach/resources.git > /dev/null 2>&1
#git push --quiet --set-upstream origin gh-pages
git push "https://${GH_TOKEN}@${GH_REPO}" master

