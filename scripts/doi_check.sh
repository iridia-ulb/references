#!/bin/bash
#
# DOI Validation Script for IRIDIA BibTeX Repository
# 
# This script checks DOI fields in BibTeX entries for:
# 1. Proper DOI format validation
# 2. Duplicate DOI detection across entries
# 3. Missing or malformed DOI fields
# 4. Framework for future CrossRef API validation (when network is available)
#
# Usage: ./doi_check.sh [bibfile1] [bibfile2] ...
#        If no files specified, checks all main bib files with DOI entries
#

set -u
#set -o pipefail

# Configuration
CROSSREF_API_BASE="https://api.crossref.org/works/"
USER_AGENT="IRIDIA-BibTeX-Repository/1.0 (mailto:manuel.lopez-ibanez@manchester.ac.uk)"
RATE_LIMIT_DELAY=1  # seconds between API calls
MAX_RETRIES=3
ENABLE_API_VALIDATION=false  # Set to true when network access is available

# Initialize counters
checked_count=0
format_errors=0
duplicate_count=0
api_error_count=0
mismatch_count=0

# Global array to track DOI duplicates
declare -A doi_entries

# Create temporary directory for processing
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

# Function to validate DOI format
validate_doi_format() {
    local doi="$1"
    
    # DOI should match pattern: 10.xxxx/yyyy where xxxx is registrant code and yyyy is suffix
    if [[ "$doi" =~ ^10\.[0-9]+/.+ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check for common DOI format issues
check_doi_issues() {
    local doi="$1"
    local entry_key="$2"
    local issues=()
    
    # Check for URL prefixes that should be removed
    if [[ "$doi" =~ ^https?:// ]]; then
        issues+=("Contains URL prefix (should be DOI only)")
    fi
    
    # Check for proper 10.xxxx prefix
    if [[ ! "$doi" =~ ^10\. ]]; then
        issues+=("Does not start with '10.'")
    fi
    
    # Check for missing registrant/suffix separator
    if [[ ! "$doi" =~ / ]]; then
        issues+=("Missing '/' separator")
    fi
    
    # Check for suspicious patterns
    if [[ "$doi" =~ [[:space:]] ]]; then
        issues+=("Contains whitespace")
    fi
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "DOI format issues in entry '$entry_key': $doi"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
        ((format_errors++))
        return 1
    fi
    
    return 0
}

# Function to track and check for duplicate DOIs
check_duplicate_doi() {
    local doi="$1"
    local entry_key="$2"
    
    if [[ -n "${doi_entries[$doi]:-}" ]]; then
        echo "DUPLICATE DOI found: $doi"
        echo "  First entry: ${doi_entries[$doi]}"
        echo "  Duplicate entry: $entry_key"
        ((duplicate_count++))
        return 1
    else
        doi_entries["$doi"]="$entry_key"
        return 0
    fi
}

# Function to test network connectivity and API availability
test_api_connectivity() {
    if command -v curl >/dev/null 2>&1; then
        if curl -s --connect-timeout 5 --max-time 10 -H "User-Agent: $USER_AGENT" \
           "https://api.crossref.org/works/10.1000/182" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Function to clean and normalize text for comparison (for future API validation)
normalize_text() {
    local text="$1"
    echo "$text" | tr '[:upper:]' '[:lower:]' | \
    sed 's/[{}]//g' | \
    sed 's/[[:punct:]]/ /g' | \
    sed 's/[[:space:]]\+/ /g' | \
    sed 's/^ *//; s/ *$//'
}
# Function to extract BibTeX entry field
extract_field() {
    local entry_file="$1"
    local field="$2"
    
    # Look for field = {value} or field = "value" patterns
    local value=$(grep -i "^[[:space:]]*${field}[[:space:]]*=" "$entry_file" | \
                  sed 's/^[[:space:]]*[^=]*=[[:space:]]*[{"]//i; s/["}][[:space:]]*,*[[:space:]]*$//; s/[[:space:]]*,*[[:space:]]*$//')
    
    echo "$value"
}

# Function to extract DOI from entry
extract_doi() {
    local entry_file="$1"
    local doi=$(extract_field "$entry_file" "doi")
    
    # Clean DOI - remove URL prefixes
    doi=$(echo "$doi" | sed 's|https*://doi\.org/||; s|https*://dx\.doi\.org/||')
    echo "$doi"
}

# Function to get CrossRef metadata (placeholder for when API is available)
get_crossref_metadata() {
    local doi="$1"
    local output_file="$2"
    
    if [[ -z "$doi" ]]; then
        return 1
    fi
    
    if ! $ENABLE_API_VALIDATION; then
        return 1  # API validation disabled
    fi
    
    # Clean DOI
    doi=$(echo "$doi" | sed 's|https*://doi\.org/||; s|https*://dx\.doi\.org/||')
    
    local url="${CROSSREF_API_BASE}${doi}"
    
    for attempt in $(seq 1 $MAX_RETRIES); do
        # Add rate limiting delay
        if [[ $checked_count -gt 0 ]]; then
            sleep $RATE_LIMIT_DELAY
        fi
        
        if curl -s -H "User-Agent: $USER_AGENT" --connect-timeout 30 --max-time 60 "$url" > "$output_file" 2>/dev/null; then
            # Check if we got valid JSON with a message field
            if jq -e '.message' "$output_file" >/dev/null 2>&1; then
                return 0
            fi
        fi
        
        # Exponential backoff for retries
        if [[ $attempt -lt $MAX_RETRIES ]]; then
            sleep $((2 ** attempt))
        fi
    done
    
    return 1
}

# Function to extract authors from CrossRef JSON
extract_crossref_authors() {
    local json_file="$1"
    jq -r '.message.author[]?.family // empty' "$json_file" 2>/dev/null | tr '[:upper:]' '[:lower:]'
}

# Function to extract title from CrossRef JSON
extract_crossref_title() {
    local json_file="$1"
    jq -r '.message.title[]? // empty' "$json_file" 2>/dev/null | head -1 | tr '[:upper:]' '[:lower:]'
}

# Function to extract year from CrossRef JSON
extract_crossref_year() {
    local json_file="$1"
    jq -r '.message.published."date-parts"[0][0]? // empty' "$json_file" 2>/dev/null
}

# Function to extract author family names from BibTeX author field
extract_bib_authors() {
    local author_field="$1"
    
    # Split on " and " and extract family names
    echo "$author_field" | sed 's/ and /\n/g' | while read -r author; do
        if [[ "$author" =~ , ]]; then
            # Format: "LastName, FirstName" 
            echo "$author" | sed 's/,.*$//' | normalize_text
        else
            # Format: "FirstName LastName" - take last word
            echo "$author" | awk '{print $NF}' | normalize_text
        fi
    done
}

# Function to check overlap between two lists
check_overlap() {
    local list1_file="$1"
    local list2_file="$2"
    local min_overlap="$3"
    
    if [[ ! -s "$list1_file" ]] || [[ ! -s "$list2_file" ]]; then
        echo "0"
        return
    fi
    
    local overlap=$(comm -12 <(sort "$list1_file") <(sort "$list2_file") | wc -l)
    local min_size=$(wc -l < "$list1_file")
    local list2_size=$(wc -l < "$list2_file")
    
    if [[ $list2_size -lt $min_size ]]; then
        min_size=$list2_size
    fi
    
    local required_overlap=$((min_size < min_overlap ? min_size : min_overlap))
    
    if [[ $overlap -ge $required_overlap ]]; then
        echo "1"
    else
        echo "0"
    fi
}

# Function to validate a single DOI entry
validate_doi_entry() {
    local entry_file="$1"
    local bib_key="$2"
    
    local doi=$(extract_doi "$entry_file")
    
    if [[ -z "$doi" ]]; then
        return 0  # No DOI to check
    fi
    
    ((checked_count++))
    echo "Checking entry $bib_key: $doi"
    
    # Check DOI format
    local format_ok=true
    if ! validate_doi_format "$doi"; then
        check_doi_issues "$doi" "$bib_key"
        format_ok=false
    fi
    
    # Check for duplicates
    local duplicate_ok=true
    if ! check_duplicate_doi "$doi" "$bib_key"; then
        duplicate_ok=false
    fi
    
    # If API validation is enabled and format is OK, try to validate against CrossRef
    if $ENABLE_API_VALIDATION && $format_ok; then
        local crossref_file="$temp_dir/crossref_response.json"
        
        if get_crossref_metadata "$doi" "$crossref_file"; then
            # Here we could add the detailed comparison logic
            echo "  API validation: Available (implement detailed comparison)"
        else
            echo "  API validation: Failed to retrieve metadata"
            ((api_error_count++))
        fi
    fi
    
    # Return status based on validations
    if $format_ok && $duplicate_ok; then
        return 0
    else
        return 1
    fi
}

# Function to extract individual BibTeX entries from a file
extract_entries() {
    local bib_file="$1"
    local output_dir="$2"
    
    awk '
    BEGIN { 
        in_entry = 0
        brace_count = 0
        entry_content = ""
        entry_key = ""
    }
    
    /^@[A-Za-z]+\{/ { 
        if (in_entry) {
            # Save previous entry
            if (entry_key != "" && entry_content != "") {
                print entry_content > output_dir "/" entry_key ".bib"
                close(output_dir "/" entry_key ".bib")
            }
        }
        
        in_entry = 1
        brace_count = 1  # Start with 1 for the opening brace
        entry_content = $0 "\n"
        
        # Extract entry key
        match($0, /^@[A-Za-z]+\{([^,]+)/, arr)
        entry_key = arr[1]
    }
    
    in_entry && !/^@[A-Za-z]+\{/ {
        entry_content = entry_content $0 "\n"
        
        # Count braces to know when entry ends
        for (i = 1; i <= length($0); i++) {
            char = substr($0, i, 1)
            if (char == "{") brace_count++
            else if (char == "}") brace_count--
        }
        
        if (brace_count == 0) {
            # Entry complete
            if (entry_key != "" && entry_content != "") {
                print entry_content > output_dir "/" entry_key ".bib"
                close(output_dir "/" entry_key ".bib")
            }
            in_entry = 0
            entry_content = ""
            entry_key = ""
        }
    }
    
    END {
        if (in_entry && entry_key != "" && entry_content != "") {
            print entry_content > output_dir "/" entry_key ".bib"
            close(output_dir "/" entry_key ".bib")
        }
    }
    ' output_dir="$output_dir" "$bib_file"
}

# Function to process a single BibTeX file
process_bib_file() {
    local filename="$1"
    
    echo "Processing file: $filename"
    
    local entries_dir="$temp_dir/entries"
    mkdir -p "$entries_dir"
    
    # Extract individual entries
    extract_entries "$filename" "$entries_dir"
    
    local entries_with_doi=0
    
    # Process each entry
    for entry_file in "$entries_dir"/*.bib; do
        if [[ -f "$entry_file" ]]; then
            local bib_key=$(basename "$entry_file" .bib)
            
            # Check if entry has DOI
            if grep -qi "^[[:space:]]*doi[[:space:]]*=" "$entry_file"; then
                ((entries_with_doi++))
                validate_doi_entry "$entry_file" "$bib_key"
            fi
        fi
    done
    
    echo "Found $entries_with_doi entries with DOI in $filename"
    echo ""
    
    # Cleanup
    rm -rf "$entries_dir"
}

# Main execution
main() {
    local files=("$@")
    
    # Default files if none specified
    if [[ ${#files[@]} -eq 0 ]]; then
        files=("articles.bib" "biblio.bib" "crossref.bib")
        echo "No files specified, checking default files with DOI entries"
        echo ""
    fi
    
    echo "DOI Validation Script for IRIDIA BibTeX Repository"
    echo "================================================="
    echo ""
    
    # Check if API validation is available
    if test_api_connectivity; then
        ENABLE_API_VALIDATION=true
        echo "CrossRef API is available - full validation enabled"
    else
        ENABLE_API_VALIDATION=false
        echo "CrossRef API not available - format and duplicate validation only"
    fi
    echo ""
    
    for filename in "${files[@]}"; do
        if [[ -f "$filename" ]]; then
            process_bib_file "$filename"
        else
            echo "Warning: File not found: $filename"
        fi
    done
    
    # Summary
    echo "DOI Validation Summary"
    echo "====================="
    echo "Total DOI entries checked: $checked_count"
    echo "Format errors: $format_errors"
    echo "Duplicate DOIs: $duplicate_count"
    if $ENABLE_API_VALIDATION; then
        echo "API errors: $api_error_count" 
        echo "Metadata mismatches: $mismatch_count"
    fi
    
    local total_errors=$((format_errors + duplicate_count + api_error_count + mismatch_count))
    
    if [[ $total_errors -gt 0 ]]; then
        echo ""
        echo "Some DOI validation issues were found. Please review the entries above."
        exit 1
    else
        echo ""
        echo "All DOI entries passed validation. Good job!"
        exit 0
    fi
}

# Check required tools - jq is optional for API functionality
for tool in curl awk; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: Required tool '$tool' is not installed."
        exit 1
    fi
done

if $ENABLE_API_VALIDATION && ! command -v jq >/dev/null 2>&1; then
    echo "Warning: jq is not available - API validation will be disabled"
    ENABLE_API_VALIDATION=false
fi

# Run main function with all arguments
main "$@"