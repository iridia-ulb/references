#!/bin/sh
if [ ! -e biblio.bib ]; then
    echo "$0: error: cannot find biblio.bib !"
    exit 1
fi
BIBFILES="authors.bib abbrev.bib journals.bib articles.bib biblio.bib crossref.bib"

tmpbib=$(mktemp --tmpdir tmpXXXXXXXXXX.bib)
tmpcitefile=$(mktemp --tmpdir citefileXXXXXXXXXX)
TIDYCONF=$(realpath scripts/tidy.conf)

bib2bib --warn-error --expand --expand-xrefs $BIBFILES --remove pdf -ob $tmpbib -oc $tmpcitefile

cd web
bibtex2html -noeprint --no-header --nodoc --html-entities -linebreak -css bibtex.css \
            --named-field url http --named-field springerlink Springer \
            --named-field supplement "supplementary material" --named-field epub epub \
            -doi-prefix 'https://doi.org/' --note annote -dl  -u \
            -s ../bibstyles/plainweb -macros-from ../macros.tex -o index  \
            -citefile $tmpcitefile $tmpbib | tee .bibtex2html-warnings

grep --quiet "Unknown macro:" .bibtex2html-warnings
if [ $? -eq 0 ]; then
    echo "Error: Please fix bibtex2html Unknown macros"
    grep "Unknown macro:" .bibtex2html-warnings
    exit 1
fi
rm -f .bibtex2html-warnings

cat header.htm index.html footer.htm > tmp.html
mv tmp.html index.html
# Add clickable anchors
sed -i 's/<a name="\([^"]\+\)">/<a href="#\1" id="\1">/g' index.html
# Use id= instead of name= (shorter and more modern).
sed -i 's/<a name=/<a id=/g' index_bib.html
#tidy -config $TIDYCONF -m index.html

cat header.htm index_bib.html footer.htm > tmp.html
mv tmp.html index_bib.html
#tidy -config $TIDYCONF -m index_bib.html

# remove temporary files
rm -f bib2html*
cd ..
