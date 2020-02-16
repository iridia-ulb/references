#!/bin/sh
if [ ! -e biblio.bib ]; then
    echo "$0: error: cannot find biblio.bib !"
    exit 1
fi
BIBFILES="authors.bib abbrev.bib journals.bib biblio.bib crossref.bib"

tmpbib=$(mktemp --tmpdir tmpXXXXXXXXXX.bib)
tmpcitefile=$(mktemp --tmpdir citefileXXXXXXXXXX)
TIDYCONF=$(realpath scripts/tidy.conf)

bib2bib --warn-error --expand --expand-xrefs $BIBFILES -ob $tmpbib -oc $tmpcitefile

cd web
bibtex2html --nodoc --html-entities -linebreak -css bibtex.css --named-field url http --named-field springerlink Springer --named-field supplement "supplementary material" --named-field pdf pdf --note annote -dl -u -s ../bibstyles/plainweb -macros-from ../macros.tex -o index -citefile $tmpcitefile $tmpbib

cat header.htm index.html footer.htm > tmp.html
mv tmp.html index.html
# Add clickable anchors
sed -i 's/<a name="\([^"]\+\)">/<a href="#\1" name="\1">/g' index.html
#tidy -config $TIDYCONF -m index.html

cat header.htm index_bib.html footer.htm > tmp.html
mv tmp.html index_bib.html
#tidy -config $TIDYCONF -m index_bib.html

# remove temporary files
rm -f bib2html*
cd ..
