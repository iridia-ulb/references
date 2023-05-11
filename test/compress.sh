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
    qpdf $QPDF_OPTIONS "$filename-tmp" "$filename-tmp2"
    echo After qpdf: $(du -h "$filename-tmp2")
    AFTER_SIZE=$(stat -c%s "$filename-tmp2")
    if (( BEFORE_SIZE > AFTER_SIZE)); then
        mv "$filename-tmp2" "$filename"
        if [ $? -ne 0 ]; then
            echo "$0: cannot overwrite $filename"
            exit 1
        fi
        echo "$0: Success !"
    fi
    rm -f "$filename-tmp" "$filename-tmp2"
done
