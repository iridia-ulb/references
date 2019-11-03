#!/bin/sh
set -u
set -e
MESSAGE=$(git log --format=%B -n 1 $TRAVIS_COMMIT)
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"
git checkout master
git add -f test/testbib.pdf
# If there are no changes to the compiled out (e.g. this is a README update) then just bail.
if git diff --cached --quiet; then
    echo "No changes to the output on this push; exiting."
    exit 0
fi

git commit --message "testbib.pdf: Regenerate (build: $TRAVIS_BUILD_NUMBER) [skip ci]."
git remote add origin-travis "https://${GH_TOKEN}@${GH_REPO}" > /dev/null 2>&1
git push  --quiet --set-upstream origin-travis

