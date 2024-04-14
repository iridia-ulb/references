#!/bin/bash
set -u

check_bad_thing() {
    WHAT=$1
    MSG=$2
    TYPE=${3:-"-e"}
    WHERE=${4:-$FILES}
    grep --quiet $TYPE $WHAT $WHERE
    if [ $? -eq 0 ]; then
        echo "Error: $MSG"
        grep -H -n $TYPE $WHAT $WHERE
        exit 1
    fi
}

check_bad_thing_E() {
    check_bad_thing "$1" "$2" "-E"
}

for filename in "$@"; do
    case "$filename" in
        *"biblio.bib")
            grep --quiet --ignore-case -F "@article" "$filename"
            if [ $? -eq 0 ]; then
                echo "Error: biblio.bib should not contain @article entries (put them in articles.bib)"
                grep -H -n --ignore-case -F "@article" "$filename"
                exit 1
            fi
            ;;
        *"articles.bib")
            grep --ignore-case -e "^@[a-z]\+" "$filename" | grep --quiet -v --ignore-case "@article"
            if [ $? -eq 0 ]; then
                echo "Error: articles.bib should only contain @article entries (put them in biblio.bib)"
                grep -H -n --ignore-case -e "^@[a-z]\+" "$filename" | grep -v --ignore-case "@article"
                exit 1
            fi
            ;;
        *"crossref.bib")
            grep --ignore-case -e "^@[a-z]\+" "$filename" | grep --quiet -v --ignore-case -e "@proceedings\|@book"
            if [ $? -eq 0 ]; then
                echo "Error: crossref.bib should only contain @proceedings or @book entries"
                grep -H -n --ignore-case -e "^@[a-z]\+" "$filename" | grep -v --ignore-case -e "@proceedings\|@book"
                exit 1
            fi
            ;;
        *"abbrev.bib"|*"journals.bib"|*"authors.bib"|*"abbrevshort.bib")
            grep --ignore-case -e "^@[a-z]\+" "$filename"  | grep --quiet --ignore-case -v -e "@string\|@preamble"
            if [ $? -eq 0 ]; then
                echo "Error: $filename should only contain @string or @preamble entries"
                grep -H -n --ignore-case -e "^@[a-z]\+" "$filename"  | grep --ignore-case -v -e "@string\|@preamble"
                exit 1
            fi
            ;;
    esac
done

checkdups=0
for filename in "$@"; do
    case "$filename" in
        *"journals.bib"|*"abbrev.bib")
            checkdups=1
            break
            ;;
        *"authors.bib")
            checkdups=1
            check_bad_thing "^@string.\+=.*[[:space:]\"][[:space:]]*[A-Z]\.\([A-Z]\.\)\+" "Initials must be separated by a space" "-e" "$filename"
            ;;

    esac
done

if [ $checkdups -ne 0 ]; then
    bibpath=$(dirname "$1")
    dups=$(cat "${bibpath}/authors.bib" "${bibpath}/journals.bib" "${bibpath}/abbrev.bib" \
        | grep '^\s*@string' \
        | sed -E 's/^\s*@string\{([^[:space:]=]+).*$/\1/' | sort --ignore-case | uniq -d -i)
    if [ ! -z "$dups" ]; then
        echo "Error: duplicated strings found!"
        for line in ${dups}; do
            grep -H -n --ignore-case '^\s*@string.*'"${line}" $@
        done
        exit 1
    fi
    # TODO: Check that strings in abbrevshort.bib also appear in either journals.bib or abbrev.bib.
fi


# FIXME: This may not work with spaces in directories.
FILES=$@


check_bad_thing "^\s*\(author\|editor\)\s\+=.*[[:space:]\"{][[:space:]]*[A-Z]\.\([A-Z]\.\)\+" "Author or editor initials must be separated by a space"
check_bad_thing "^\s*\(biburl\|timestamp\|article-number\|copyright\)" "Please remove these fields" "--ignore-case -e"
check_bad_thing "^\s*journaltitle" "'journaltitle' should be just 'journal'" "--ignore-case -e"
check_bad_thing "doi[[:space:]]*=.\+http" "the doi field should not be an URL"
check_bad_thing "^\s*@[a-zA-Z]\+[([]" "Invalid character found after the type, you should use '{', e.g., @Book{"
check_bad_thing "^\s*pages\s\+=.\+[0-9]\+-[0-9]\+" "Use double dash \"--\" for pages"

# These look similar but they are different.
BADCHARS="⁄∕−―—–´’"
check_bad_thing "[$BADCHARS]"  "Please do not use these UTF8 characters: $BADCHARS"
check_bad_thing "\\\'\\\i" "Please do not use \'\i because it does not work in biber. Use \'i instead"
check_bad_thing_E "\\\'{\\\i}" "Please do not use \'{\i} because it does not work in biber. Use \'i instead"
check_bad_thing '\\[`^"]\\\i' 'Please do not use \`\i or \"\i or \^\i because it does not work in biber. Use \`i or \"i or \^i instead'
check_bad_thing_E '\\[`^"]{\\\i}' 'Please do not use \`{\i} or \"{\i} or \^{\i} because it does not work in biber. Use \`i or \"i or \^i instead'
