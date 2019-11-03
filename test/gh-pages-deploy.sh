#!/bin/bash
set -e # Exit with nonzero exit code if anything fails
set -u
SOURCE_BRANCH="master"
TARGET_BRANCH="gh-pages"

# Pull requests and commits to other branches shouldn't try to deploy, just build to verify
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "Skipping gh-pages deploy"
    exit 0
fi

# Save some useful information
SHA=`git rev-parse --verify HEAD`

git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

if [ ! -e references.html ]; then
    echo "$0: error: cannot find references.html !"
    exit 1
fi

git checkout $TARGET_BRANCH
git status
git reset --hard
git status
mv references.html index.html
mv references_bib.html index_bib.html
mv tmp-bibtex.css bibtex.css
git add -f index.html index_bib.html bibtex.css
git status

# If there are no changes to the compiled out (e.g. this is a README update) then just bail.
if git diff --quiet; then
    echo "No changes to the output on this push; exiting."
    exit 0
fi

# Commit the "changes", i.e. the new version.
# The delta will show diffs between new and old versions.
git commit -m "Deploy to GitHub Pages: ${SHA}"

git remote add origin-travis "https://${GH_TOKEN}@${GH_REPO}" > /dev/null 2>&1
git push  --quiet --set-upstream origin-travis $TARGET_BRANCH

