#!/bin/sh
if [ ! -e biblio.bib ]; then
    cd ..
    if [ ! -e biblio.bib ]; then
        echo "$0: error: cannot find references.html !"
        exit 1
    fi
fi
tmpbib=$(mktemp --tmpdir tmpXXXXXXXXXX.bib)
tmpcitefile=$(mktemp --tmpdir citefileXXXXXXXXXX)


bib2bib --warn-error --expand --expand-xrefs authors.bib abbrev.bib journals.bib biblio.bib crossref.bib -ob $tmpbib -oc $tmpcitefile

bibtex2html --title "IRIDIA BibTeX Repository" --html-entities --named-field url http --named-field springerlink Springer --named-field supplement "supplementary material" --named-field pdf PDF -dl -u -s bibstyles/plainweb -macros-from macros.tex -o index -citefile $tmpcitefile $tmpbib

# We need to do this so it will not get overwritten when switching branches
mv index.html references.html
mv index_bib.html references_bib.html
# remove temporary files
rm -f bib2html*
