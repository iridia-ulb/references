#!/bin/bash
set -u
set -o pipefail

for filename in "$@"; do
    case "$filename" in
        *"biblio.bib"*)
            grep --quiet --ignore-case "@article" "$filename"
            if [ $? -eq 0 ]; then
                echo "Error: biblio.bib should not contain @article entries (put them in articles.bib)"
                grep -H -n --ignore-case "@article" "$filename"
                exit 1
            fi
            ;;
        *"articles.bib"*)
            grep --ignore-case -e "^@[a-z]\+" "$filename" | grep --quiet -v --ignore-case "@article"
            if [ $? -eq 0 ]; then
                echo "Error: articles.bib should only contain @article entries (put them in biblio.bib)"
                grep -H -n --ignore-case -e "^@[a-z]\+" "$filename" | grep -v --ignore-case "@article"
                exit 1
            fi
            ;;
        *"crossref.bib"*)
            grep --ignore-case -e "^@[a-z]\+" "$filename" | grep --quiet -v --ignore-case -e "@proceedings\|@book"
            if [ $? -eq 0 ]; then
                echo "Error: crossref.bib should only contain @proceedings or @book entries"
                grep -H -n --ignore-case -e "^@[a-z]\+" "$filename" | grep -v --ignore-case -e "@proceedings\|@book"
                exit 1
            fi
            ;;
        *"abbrev.bib"*|*"journals.bib"*|*"authors.bib"*|*"abbrevshort.bib"*)
            grep --ignore-case -e "^@[a-z]\+" "$filename"  | grep --quiet --ignore-case -v -e "@string\|@preamble"
            if [ $? -eq 0 ]; then
                echo "Error: $filename should only contain @string or @preamble entries"
                grep -H -n --ignore-case -e "^@[a-z]\+" "$filename"  | grep --ignore-case -v -e "@string\|@preamble"
                exit 1
            fi
            ;;
    esac
done

# FIXME: This may not work with spaces in directories.
FILES=$@

check_bad_thing() {
    WHAT=$1
    MSG=$2
    TYPE=${3:-"-e"}
    grep --quiet $TYPE $WHAT $FILES
    if [ $? -eq 0 ]; then
        echo "Error: $MSG"
        grep -H -n $TYPE $WHAT $FILES
        exit 1
    fi
}

check_bad_thing_E() {
    check_bad_thing "$1" "$2" "-E"
}

check_bad_thing "^\s*\(biburl\|timestamp\|article-number\|copyright\)" "Please remove these fields" "--ignore-case -e"

check_bad_thing "doi[[:space:]]*=.\+http" "the doi field should not be an URL"
# These look similar but they are different.
BADCHARS="⁄∕−―—–´"
check_bad_thing "[$BADCHARS]"  "Please do not use these UTF8 characters: $BADCHARS"
check_bad_thing "\\\'\\\i" "Please do not use \'\i because it does not work in biber. Use \'i instead"

check_bad_thing_E "\\\'{\\\i}" "Please do not use \'{\i} because it does not work in biber. Use \'i instead"
