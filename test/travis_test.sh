#!/bin/bash
set -u
set -o pipefail
latexmk -halt-on-error -interaction=nonstopmode -gg --pdf testbib.tex | tee .bibtex-warnings
if [ $? -ne 0 ]; then
    echo "Error: latexmk failed"
    exit 1
fi
grep --quiet "Warning--" .bibtex-warnings
if [ $? -eq 0 ]; then
    echo "Error: Please fix bibtex Warnings:"
    grep "Warning--" .bibtex-warnings
    exit 1
fi
echo "No bibtex warnings! Good job!"
exit 0
