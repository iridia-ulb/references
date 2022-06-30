#!/bin/bash
set -u
set -o pipefail
PATH=/tmp/texlive/bin/x86_64-linux:$PATH

if [ ! -r ../biblio.bib ]; then
    echo "Error ../biblio.bib not found. This script must be run in test/"
    exit 1
fi
 
travis_fold_start() {
    if [ ! -z ${TRAVIS:-} ]; then
        echo -e "travis_fold:start: $1\033[33;1m$2\033[0m"
    else
        echo -e "::group:: $1 \033[33;1m$2\033[0m"
    fi
}

travis_fold_end() {
    if [ ! -z ${TRAVIS:-} ]; then
        echo -e "\ntravis_fold:end: $1\r"
    else
        echo -e "\n::endgroup::\n"
    fi
}

check_bad_thing() {
    WHAT=$1
    MSG=$2
    grep --quiet -e $WHAT ../*.bib
    if [ $? -eq 0 ]; then
        echo "Error: $MSG"
        grep -n -e $WHAT ../*.bib
        exit 1
    fi
}
# FIXE: avoid this duplication
check_bad_thing_E() {
    WHAT=$1
    MSG=$2
    grep --quiet -E $WHAT ../*.bib
    if [ $? -eq 0 ]; then
        echo "Error: $MSG"
        grep -n -E $WHAT ../*.bib
        exit 1
    fi
}

check_bad_thing "doi[[:space:]]*=.\+http" "the doi field should not be an URL"
# These look similar but they are different.
BADCHARS="⁄∕−―—–´"
check_bad_thing "[$BADCHARS]"  "Please do not use these UTF8 characters: $BADCHARS"
check_bad_thing "\\\'\\\i" "Please do not use \'\i because it does not work in biber. Use \'i instead"

check_bad_thing_E "\\\'{\\\i}" "Please do not use \'{\i} because it does not work in biber. Use \'i instead"

latexmake() {
    TEXMAIN=$1
    BST=$2
    travis_fold_start latexmk.1 "latexmk $TEXMAIN $BST"
    rm -f *.bbl *.aux *.log *.out *.bcf *.blg

    if [ -h tmp.bst ]; then
        rm -f tmp.bst
    fi
    if [ $bst != "" ]; then
        ln -s ${BST}.bst tmp.bst
    fi
    
    latexmk -halt-on-error -interaction=nonstopmode -gg --pdf $TEXMAIN | tee .bibtex-warnings
    if [ $? -ne 0 ]; then
        travis_fold_end latexmk.1
        echo "Error: latexmk failed"
        exit 1
    fi

    grep --quiet "Warning--" .bibtex-warnings
    if [ $? -eq 0 ]; then
        travis_fold_end latexmk.1
        echo "Error: Please fix bibtex Warnings:"
        grep "Warning--" .bibtex-warnings
        exit 1
    fi
    
    grep --quiet "WARN" .bibtex-warnings
    if [ $? -eq 0 ]; then
        travis_fold_end latexmk.1
        echo "Error: Please fix biblatex Warnings:"
        grep "WARN" .bibtex-warnings
        exit 1
    fi
    travis_fold_end latexmk.1
}

TEXMAIN="testbib.tex"
travis_fold_start texliveonfly.1 "texliveonfly $TEXMAIN"
texliveonfly $TEXMAIN
travis_fold_end texliveonfly.1

for main in "testbib" "testshortbib"; do
    # FIXME: It doesn't compile cleanly.
    #for bst in "../bibstyles/ACM-Reference-Format" "testbib"; do
    for bst in "../bibstyles/splncs04abbrev" "../bibstyles/abbrvnatamp" "$main"; do
        latexmake "${main}.tex" "$bst"
    done
done
latexmake "testbiblatex.tex" ""

echo "No bibtex warnings! Good job!"
exit 0
