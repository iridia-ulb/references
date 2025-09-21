#!/bin/bash
#
# Extract changed DOI entries from git diff
# This script analyzes git diff to identify BibTeX entries with modified DOI fields
#
# Usage: extract_changed_dois.sh [base_ref]
#        base_ref: Git reference to compare against (default: HEAD~1)
#
# Output: Space-separated list of entry keys that have modified DOI fields
#

set -u

# Get base reference for comparison
if [ $# -gt 0 ]; then
  base_ref="$1"
else
  base_ref="HEAD~1"
fi

echo "Comparing against base ref: $base_ref" >&2

# Get the changed entries from modified bib files
changed_entries=""

# Extract DOI entries from changed lines in bib files
for file in articles.bib biblio.bib crossref.bib; do
  if git diff --name-only $base_ref HEAD | grep -q "^$file$"; then
    echo "Processing changes in $file" >&2

    # Get all entries that have DOI changes (added or modified DOI lines)
    # This creates a temp file with the diff and processes it
    git diff $base_ref HEAD -- "$file" > /tmp/diff_$file

    # Find entries where DOI field was added or modified
    grep -n "^[+-].*doi\s*=" /tmp/diff_$file | while IFS=: read linenum line; do
      # Get the entry key by looking backwards from the DOI line for the entry start
      entry_start=$(head -n $linenum /tmp/diff_$file | grep -n "^[+-]@[A-Za-z]*{" | tail -1)
      if [ -n "$entry_start" ]; then
        entry_line=$(echo "$entry_start" | cut -d: -f2)
        entry_key=$(echo "$entry_line" | sed 's/^[+-]@[A-Za-z]*{\([^,}]*\).*/\1/')
        if [ -n "$entry_key" ]; then
          echo "Found changed DOI in entry: $entry_key" >&2
          changed_entries="$changed_entries $entry_key"
        fi
      fi
    done

    rm -f /tmp/diff_$file
  fi
done

# Remove duplicates and clean up
changed_entries=$(echo "$changed_entries" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)

# Output the result to stdout
echo "$changed_entries"
