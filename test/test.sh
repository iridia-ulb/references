#!/bin/bash
set -u
set -o pipefail
PATH=/tmp/texlive/bin/x86_64-linux:$PATH

if [ ! -r ../biblio.bib ]; then
    echo "Error ../biblio.bib not found. This script must be run in test/"
    exit 1
fi

./fast_check.sh ../*.bib || exit 1

fold_start() {
    echo -e "::group:: $1 \033[33;1m$2\033[0m"
}

fold_end() {
    echo -e "\n::endgroup::\n"
}

latexmake() {
    TEXMAIN=$1
    BST=$2
    fold_start latexmk.1 "latexmk $TEXMAIN $BST"
    rm -f *.bbl *.aux *.log *.out *.bcf *.blg *.fls *.hd *.fdb_latexmk *.run.xml *.syctex.gz

    if [ -h tmp.bst ]; then
        rm -f tmp.bst
    fi
    if [ "$BST" != "" ]; then
        ln -s ${BST}.bst tmp.bst
    fi

    latexmk -silent -halt-on-error -interaction=nonstopmode -gg --pdf $TEXMAIN | tee .bibtex-warnings
    if [ $? -ne 0 ]; then
        fold_end latexmk.1
        echo "Error: latexmk failed"
        LOGFILE=${TEXMAIN%.*}.log
        cat "$LOGFILE"
        exit 1
    fi

    grep --quiet "Warning--" .bibtex-warnings
    if [ $? -eq 0 ]; then
        fold_end latexmk.1
        echo "Error: Please fix bibtex Warnings:"
        grep "Warning--" .bibtex-warnings
        exit 1
    fi

    grep --quiet "WARN" .bibtex-warnings
    if [ $? -eq 0 ]; then
        fold_end latexmk.1
        echo "Error: Please fix biblatex Warnings:"
        grep "WARN" .bibtex-warnings
        exit 1
    fi
    fold_end latexmk.1
}

TEXMAIN="testbib.tex"
# FIXME: This doesn't seem to do anything useful.
# fold_start texliveonfly.1 "texliveonfly $TEXMAIN"
# texliveonfly $TEXMAIN
# fold_end texliveonfly.1

# Support single test mode
if [ "${1:-}" = "-single" ]; then
    TEXMAIN="$2"
    BST="${3:-}"
    latexmake "$TEXMAIN" "$BST"
else
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
