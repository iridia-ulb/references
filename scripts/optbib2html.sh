#!/bin/sh
if [ ! -e biblio.bib ]; then
    echo "$0: error: cannot find biblio.bib !"
    exit 1
fi

tmpbib=$(mktemp --tmpdir tmpXXXXXXXXXX.bib)
tmpcitefile=$(mktemp --tmpdir citefileXXXXXXXXXX)

bib2bib --warn-error --expand --expand-xrefs authors.bib abbrev.bib journals.bib biblio.bib crossref.bib -ob $tmpbib -oc $tmpcitefile

cd web
bibtex2html --nodoc --html-entities -linebreak -css bibtex.css --named-field url http --named-field springerlink Springer --named-field supplement "supplementary material"  --named-field pdf pdf -dl -u -s ../bibstyles/plainweb -macros-from ../macros.tex -o index -citefile $tmpcitefile $tmpbib

cat header.htm index.html footer.htm > tmp.html
mv tmp.html index.html
cat header.htm index_bib.html footer.htm > tmp.html
mv tmp.html index_bib.html

# remove temporary files
rm -f bib2html*
cd ..
