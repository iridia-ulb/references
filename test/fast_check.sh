#!/bin/bash
set -u
set -o pipefail

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

check_bad_thing "doi[[:space:]]*=.\+http" "the doi field should not be an URL"
# These look similar but they are different.
BADCHARS="⁄∕−―—–´"
check_bad_thing "[$BADCHARS]"  "Please do not use these UTF8 characters: $BADCHARS"
check_bad_thing "\\\'\\\i" "Please do not use \'\i because it does not work in biber. Use \'i instead"

check_bad_thing_E "\\\'{\\\i}" "Please do not use \'{\i} because it does not work in biber. Use \'i instead"

