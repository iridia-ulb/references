#!/bin/bash
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 BRANCH_NAME DIRECTORY" >&2
  exit 1
fi

if [ ! -d "$2" ]; then
    echo "Directory $2 does not exist" >&2
    echo "Usage: $0 BRANCH_NAME DIRECTORY" >&2
    exit 1
fi
if [ ! -r "./biblio.bib" ]; then
  echo "This command must be run from the root of https://github.com/iridia-ulb/references" >&2
  exit 1
fi
# Exit when any command fails
set -e
BRANCH="$1"
DIR="$2"
git worktree add -B "$BRANCH" "$DIR/bib"
pushd "$DIR"
cat <<'EOF' >> .gitignore
bib/*
!bib/*.bib
EOF
cp bib/test/.latexmkrc .
git add -f .gitignore .latexmkrc bib/README.md bib/*.bib
git ci -a -m "Setup https://github.com/iridia-ulb/references"
git push
popd
echo "$0: Please add \bibliography{bib/abbrev,bib/journals,bib/authors,bib/articles,bib/biblio,bib/crossref} to the main.tex file"
echo "$0: All done!"
exit 0
