#!/bin/sh
MESSAGE=$(git log --format=%B -n 1 $TRAVIS_COMMIT)
#git config user.email "travis@travis-ci.com"
#git config user.name "Travis CI"
#git checkout -b master
git add test/testbib.pdf
git commit --message "testbib.pdf: $MESSAGE $TRAVIS_BUILD_NUMBER"
#git remote add origin-pages https://${GH_TOKEN}@github.com/MVSE-outreach/resources.git > /dev/null 2>&1
#git push --quiet --set-upstream origin gh-pages
git push "https://${TRAVIS_SECURE_TOKEN_NAME}@${GH_REPO}" master
