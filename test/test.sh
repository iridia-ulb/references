#!/bin/bash
set -u
set -o pipefail
PATH=/tmp/texlive/bin/x86_64-linux:$PATH

if [ ! -r ../biblio.bib ]; then
    echo "Error ../biblio.bib not found. This script must be run in test/"
    exit 1
fi

./fast_check.sh ../*.bib || exit 1

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

latexmake() {
    TEXMAIN=$1
    BST=$2
    travis_fold_start latexmk.1 "latexmk $TEXMAIN $BST"
    rm -f *.bbl *.aux *.log *.out *.bcf *.blg *.fls *.hd *.fdb_latexmk *.run.xml *.syctex.gz

    if [ -h tmp.bst ]; then
        rm -f tmp.bst
    fi
    if [ "$BST" != "" ]; then
        ln -s ${BST}.bst tmp.bst
    fi
    
    latexmk -silent -halt-on-error -interaction=nonstopmode -gg --pdf $TEXMAIN | tee .bibtex-warnings
    if [ $? -ne 0 ]; then
        travis_fold_end latexmk.1
        echo "Error: latexmk failed"
        LOGFILE=${TEXMAIN%.*}.log
        cat "$LOGFILE"
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
# Support single test mode
if [ "${1:-}" = "-single" ]; then
    TEXMAIN="$2"
    BST="$3"
    latexmake "$TEXMAIN" "$BST"
else
    # Default: run all tests
    for main in "testbib" "testshortbib"; do
        # FIXME: Too many warnings
        # "../bibstyles/ACM-Reference-Format" 
        for bst in "../bibstyles/splncs04abbrev" "../bibstyles/abbrvnatamp" "$main"; do
            latexmake "${main}.tex" "$bst"
        done
    done
    latexmake "testbiblatex.tex" ""
fi

echo "No bibtex warnings! Good job!"
exit 0
