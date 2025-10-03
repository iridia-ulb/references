#!/bin/bash
set -u
set -o pipefail
PATH=/tmp/texlive/bin/x86_64-linux:$PATH

if [ ! -r ../biblio.bib ]; then
    echo "Error ../biblio.bib not found. This script must be run in test/"
    exit 1
fi

fold_start() {
    echo -e "::group:: $1 \033[33;1m$2\033[0m"
}

fold_end() {
    echo -e "\n::endgroup::\n"
}

latexmake() {
    local TEXMAIN="$1"
    local BST="$2"
    local W_AS_ERROR=${3:-1}
    fold_start latexmk.1 "latexmk $TEXMAIN $BST"
    rm -f *.bbl *.aux *.log *.out *.bcf *.blg *.fls *.hd *.fdb_latexmk *.run.xml *.syctex.gz

    if [ -h tmp.bst ]; then
        rm -f tmp.bst
    fi
    if [ "$BST" != "" ]; then
        ln -s "${BST}.bst" tmp.bst
    fi

    latexmk -silent -halt-on-error -interaction=nonstopmode -gg --pdf "$TEXMAIN" | tee .bibtex-warnings
    if [ $? -ne 0 ]; then
        fold_end latexmk.1
        echo "Error: latexmk failed"
        cat "${TEXMAIN%.*}.log"
        exit 1
    fi

    if [ $W_AS_ERROR -eq 1 ]; then
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
    # FIXME: ACM-Reference-Format produces too many warnings
    if [[ $BST == *"ACM-Reference-Format"* ]]; then
        echo "BibTeX warnings are not errors"
        W_AS_ERROR=0
    else
        W_AS_ERROR=1
    fi
    latexmake "$TEXMAIN" "$BST" $W_AS_ERROR
else
    for main in "testbib" "testshortbib"; do
        for bst in "../bibstyles/splncs04abbrev" "../bibstyles/abbrvnatamp" "$main"; do
            latexmake "${main}.tex" "$bst"
        done
        # FIXME: Too many warnings
        for bst in "../bibstyles/ACM-Reference-Format"; do
            latexmake "${main}.tex" "$bst" 0
        done
    done
    latexmake "testbiblatex.tex" ""
fi
echo "No errors! Good job!"
exit 0
