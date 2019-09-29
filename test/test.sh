#!/bin/sh
latexmk -halt-on-error -g --pdf testbib.tex | tee /dev/stderr | grep -F "Warning--" --quiet
if [ $? -eq 0 ]; then
    echo "Error: Please fix bibtex Warnings"
    exit 1
fi
exit 0
