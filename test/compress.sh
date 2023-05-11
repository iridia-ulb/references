#!/bin/bash
set -u
set -o pipefail

QPDF_OPTIONS="--compress-streams=y --object-streams=generate --recompress-flate --compression-level=9"
GS_OPTIONS="-dPDFSETTINGS=/ebook -dCompatibilityLevel=1.5 -dAutoRotatePages=/None -dPrinted=false -dNOPLATFONTS -dSAFER -dEmbedAllFonts=true"

for filename in "$@"; do
    echo Before: $(du -h "$filename")
    BEFORE_SIZE=$(stat -c%s "$filename")
    gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite $GS_OPTIONS -sOutputFile="$filename-tmp" "$filename"
    echo After gs: $(du -h "$filename-tmp")
    qpdf $QPDF_OPTIONS "$filename" "$filename-tmp"
    echo After qpdf: $(du -h "$filename-tmp")
    AFTER_SIZE=$(stat -c%s "$filename-tmp")
    if (( BEFORE_SIZE > AFTER_SIZE)); then
        mv "$filename-tmp" "$filename"
        if [ $? -ne 0 ]; then
            echo "$0: cannot overwrite $filename"
            exit 1
        fi
        echo "$0: Success !"
    fi
done
