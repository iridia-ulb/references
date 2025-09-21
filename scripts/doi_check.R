#!/usr/bin/env Rscript
#
# DOI Validation Script for IRIDIA BibTeX Repository
#
# This script provides comprehensive DOI validation including:
# 1. DOI format validation
# 2. Duplicate DOI detection across entries
# 3. CrossRef API validation and metadata comparison (when network available)
# 4. Missing or malformed DOI field detection
#
# Usage: Rscript doi_check.R [bibfile1] [bibfile2] ...
#        If no files specified, checks all main bib files with DOI entries
#

options(warn=2)  # Turn warnings into errors

# Function to install packages if not available
install_if_missing <- function(package) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    cat("Installing required package:", package, "\n")
    install.packages(package, repos = "https://cran.r-project.org/")
    library(package, character.only = TRUE)
  }
}

# Install required packages if not available
install_if_missing("rbibutils")
install_if_missing("jsonlite")
install_if_missing("httr")

# Configuration
CROSSREF_API_BASE <- "https://api.crossref.org/works/"
USER_AGENT <- "IRIDIA-BibTeX-Repository/1.0 (mailto:manuel.lopez-ibanez@manchester.ac.uk)"
RATE_LIMIT_DELAY <- 1  # seconds between API calls
MAX_RETRIES <- 3

# Initialize counters
checked_count <- 0
format_errors <- 0
duplicate_count <- 0
api_error_count <- 0
mismatch_count <- 0

# Global list to track DOI duplicates
doi_entries <- list()

# Check if CrossRef API is available
api_available <- FALSE
tryCatch({
  test_response <- GET("https://api.crossref.org/works/10.1000/182",
                       add_headers("User-Agent" = USER_AGENT),
                       timeout(10))
  api_available <- (status_code(test_response) == 200)
}, error = function(e) {
  api_available <<- FALSE
})

# Function to validate DOI format
validate_doi_format <- function(doi) {
  # DOI should match pattern: 10.xxxx/yyyy where xxxx is registrant code and yyyy is suffix
  return(grepl("^10\\.[0-9]+/.+", doi))
}

# Function to check for common DOI format issues
check_doi_issues <- function(doi, entry_key) {
  issues <- c()

  # Check for URL prefixes that should be removed
  if (grepl("^https?://", doi)) {
    issues <- c(issues, "Contains URL prefix (should be DOI only)")
  }

  # Check for proper 10.xxxx prefix
  if (!grepl("^10\\.", doi)) {
    issues <- c(issues, "Does not start with '10.'")
  }

  # Check for missing registrant/suffix separator
  if (!grepl("/", doi)) {
    issues <- c(issues, "Missing '/' separator")
  }

  # Check for suspicious patterns
  if (grepl("[[:space:]]", doi)) {
    issues <- c(issues, "Contains whitespace")
  }

  if (length(issues) > 0) {
    cat("DOI format issues in entry '", entry_key, "': ", doi, "\n", sep="")
    for (issue in issues) {
      cat("  - ", issue, "\n", sep="")
    }
    format_errors <<- format_errors + 1
    return(FALSE)
  }

  return(TRUE)
}

# Function to track and check for duplicate DOIs
check_duplicate_doi <- function(doi, entry_key) {
  if (!is.null(doi_entries[[doi]])) {
    cat("DUPLICATE DOI found: ", doi, "\n", sep="")
    cat("  First entry: ", doi_entries[[doi]], "\n", sep="")
    cat("  Duplicate entry: ", entry_key, "\n", sep="")
    duplicate_count <<- duplicate_count + 1
    return(FALSE)
  } else {
    doi_entries[[doi]] <<- entry_key
    return(TRUE)
  }
}

# Function to clean and normalize text for comparison
normalize_text <- function(text) {
  if (is.null(text) || is.na(text) || length(text) == 0) return("")
  # Convert to lowercase, remove extra whitespace, punctuation variations
  text <- tolower(as.character(text))
  text <- gsub("[{}]", "", text)  # Remove LaTeX braces
  text <- gsub("[[:punct:]]", " ", text)  # Replace punctuation with spaces
  text <- gsub("\\s+", " ", text)  # Collapse multiple spaces
  text <- trimws(text)
  return(text)
}

# Function to compare names (handles variations in author formatting)
compare_names <- function(bib_authors, crossref_authors) {
  if (is.null(bib_authors) || is.null(crossref_authors)) return(FALSE)

  # Extract family names from both sources
  bib_names <- c()
  if (is.character(bib_authors)) {
    # Simple string parsing for BibTeX authors
    author_parts <- strsplit(bib_authors, " and ")[[1]]
    for (author in author_parts) {
      # Try to extract family name (last part after last comma or space)
      if (grepl(",", author)) {
        family <- trimws(strsplit(author, ",")[[1]][1])
      } else {
        parts <- strsplit(trimws(author), " ")[[1]]
        family <- parts[length(parts)]
      }
      bib_names <- c(bib_names, normalize_text(family))
    }
  }

  # Extract family names from CrossRef JSON
  crossref_names <- c()
  if (is.list(crossref_authors)) {
    for (author in crossref_authors) {
      if (!is.null(author$family)) {
        crossref_names <- c(crossref_names, normalize_text(author$family))
      }
    }
  }

  # Check if there's significant overlap in family names
  if (length(bib_names) == 0 || length(crossref_names) == 0) return(FALSE)
  overlap <- sum(bib_names %in% crossref_names)
  return(overlap >= min(2, min(length(bib_names), length(crossref_names)) * 0.5))
}

# Function to query CrossRef API for DOI metadata
get_crossref_metadata <- function(doi) {
  if (is.null(doi) || is.na(doi) || doi == "" || !api_available) return(NULL)

  # Clean DOI
  doi <- gsub("https?://doi.org/", "", doi)
  doi <- gsub("https?://dx.doi.org/", "", doi)

  url <- paste0(CROSSREF_API_BASE, doi)

  for (attempt in 1:MAX_RETRIES) {
    tryCatch({
      # Add delay for rate limiting
      if (checked_count > 0) Sys.sleep(RATE_LIMIT_DELAY)

      response <- GET(url,
                      add_headers("User-Agent" = USER_AGENT),
                      timeout(30))

      if (status_code(response) == 200) {
        content <- content(response, "text", encoding = "UTF-8")
        data <- fromJSON(content, simplifyVector = FALSE)
        return(data$message)
      } else if (status_code(response) == 404) {
        cat("Warning: DOI not found:", doi, "\n")
        return(NULL)
      } else {
        cat("Warning: HTTP", status_code(response), "for DOI:", doi, "\n")
        if (attempt == MAX_RETRIES) return(NULL)
      }
    }, error = function(e) {
      cat("Error querying DOI", doi, ":", e$message, "\n")
      if (attempt == MAX_RETRIES) return(NULL)
    })

    # Exponential backoff for retries
    if (attempt < MAX_RETRIES) Sys.sleep(2^attempt)
  }

  return(NULL)
}

# Function to compare BibTeX entry with CrossRef metadata
compare_entry_with_crossref <- function(bib_entry, bib_key) {
  doi <- bib_entry$doi
  if (is.null(doi) || is.na(doi) || doi == "") return(TRUE)

  crossref_data <- get_crossref_metadata(doi)

  if (is.null(crossref_data)) {
    api_error_count <<- api_error_count + 1
    return(FALSE)
  }

  # Compare title
  bib_title <- normalize_text(bib_entry$title)
  crossref_title <- normalize_text(paste(crossref_data$title, collapse = " "))

  title_match <- FALSE
  if (bib_title != "" && crossref_title != "") {
    # Check if titles have significant overlap (handle variations)
    title_words_bib <- strsplit(bib_title, " ")[[1]]
    title_words_cr <- strsplit(crossref_title, " ")[[1]]
    if (length(title_words_bib) > 0 && length(title_words_cr) > 0) {
      overlap <- sum(title_words_bib %in% title_words_cr)
      title_match <- overlap >= min(3, min(length(title_words_bib), length(title_words_cr)) * 0.6)
    }
  }

  # Compare authors
  author_match <- compare_names(bib_entry$author, crossref_data$author)

  # Compare year
  bib_year <- as.character(bib_entry$year)
  crossref_year <- ""
  if (!is.null(crossref_data$published) && !is.null(crossref_data$published$`date-parts`)) {
    crossref_year <- as.character(crossref_data$published$`date-parts`[[1]][1])
  }
  year_match <- (bib_year == crossref_year)

  # Overall match assessment
  matches <- sum(c(title_match, author_match, year_match))
  is_match <- matches >= 2  # At least 2 out of 3 should match

  if (!is_match) {
    mismatch_count <<- mismatch_count + 1
    cat("MISMATCH found for entry", bib_key, ":\n")
    cat("  DOI:", doi, "\n")
    cat("  Title match:", title_match, "\n")
    cat("    BibTeX:", substr(bib_title, 1, 80), "\n")
    cat("    CrossRef:", substr(crossref_title, 1, 80), "\n")
    cat("  Author match:", author_match, "\n")
    cat("  Year match:", year_match, "(", bib_year, "vs", crossref_year, ")\n")
    cat("\n")
  }

  return(is_match)
}

# Function to validate a single DOI entry
validate_doi_entry <- function(bib_entry, bib_key) {
  doi <- bib_entry$doi
  if (is.null(doi) || is.na(doi) || doi == "") return(TRUE)

  checked_count <<- checked_count + 1
  cat("Checking entry", bib_key, ":", doi, "\n")

  # Clean DOI - remove URL prefixes
  cleaned_doi <- gsub("https?://doi\\.org/", "", doi)
  cleaned_doi <- gsub("https?://dx\\.doi\\.org/", "", cleaned_doi)

  # Check DOI format
  format_ok <- TRUE
  if (!validate_doi_format(cleaned_doi)) {
    format_ok <- check_doi_issues(cleaned_doi, bib_key)
  }

  # Check for duplicates
  duplicate_ok <- check_duplicate_doi(cleaned_doi, bib_key)

  # If API validation is available and format is OK, try to validate against CrossRef
  api_ok <- TRUE
  if (api_available && format_ok) {
    # Update the entry with cleaned DOI for API validation
    bib_entry$doi <- cleaned_doi
    api_ok <- compare_entry_with_crossref(bib_entry, bib_key)
  }

  # Return status based on validations
  return(format_ok && duplicate_ok && api_ok)
}

# Function to process a single BibTeX file
process_bib_file <- function(filename, changed_entries = NULL) {
  cat("Processing file:", filename, "\n")
  # Define macro files for parsing
  if (endsWith(filename, "crossref.bib"))
    macro_files <- c("abbrev.bib", "authors.bib")
  else if (endsWith(filename, "articles.bib"))
    macro_files <- c("abbrev.bib", "authors.bib", "journals.bib")
  else if (endsWith(filename, "biblio.bib"))
    macro_files <- c("abbrev.bib", "authors.bib", "crossref.bib")
  else
    macro_files <- NULL

  tryCatch({
    # Read bibliography with macro files
    bibs <- readBib(filename, direct=TRUE, macros=macro_files)

    entries_with_doi <- 0
    entries_checked <- 0

    for (i in 1:length(bibs)) {
      entry <- unclass(bibs[[i]])[[1L]]
      key <- attr(entry, "key")

      if (!is.null(entry$doi)) {
        entries_with_doi <- entries_with_doi + 1

        # If changed_entries is specified, only check those entries
        if (is.null(changed_entries) || key %in% changed_entries) {
          validate_doi_entry(entry, key)
          entries_checked <- entries_checked + 1
        }
      }
    }

    if (!is.null(changed_entries) && length(changed_entries) > 0) {
      cat("Found", entries_with_doi, "entries with DOI in", filename, ", checked", entries_checked, "changed entries\n\n")
    } else {
      cat("Found", entries_with_doi, "entries with DOI in", filename, "\n\n")
    }

  }, error = function(e) {
    cat("Error processing", filename, ":", e$message, "\n\n")
    api_error_count <<- api_error_count + 1
  })
}

# Main execution
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  # Parse arguments for changed entries
  changed_entries <- NULL
  changed_entries_flag <- which(args == "--changed-entries")
  if (length(changed_entries_flag) > 0 && length(args) > changed_entries_flag) {
    changed_entries_str <- args[changed_entries_flag + 1]
    changed_entries <- trimws(strsplit(changed_entries_str, " ")[[1]])
    changed_entries <- changed_entries[changed_entries != ""]
    # Remove the flag and entries from args
    args <- args[-c(changed_entries_flag, changed_entries_flag + 1)]
  }

  # Default files if none specified
  if (length(args) == 0) {
    args <- c("articles.bib", "biblio.bib", "crossref.bib")
    if (is.null(changed_entries)) {
      cat("No files specified, checking default files with DOI entries\n\n")
    }
  }

  cat("DOI Validation Script for IRIDIA BibTeX Repository\n")
  cat("=================================================\n\n")

  # Report API availability
  if (api_available) {
    cat("CrossRef API is available - full validation enabled\n\n")
  } else {
    cat("CrossRef API not available - format and duplicate validation only\n\n")
  }

  # Report mode
  if (!is.null(changed_entries) && length(changed_entries) > 0) {
    cat("Running incremental DOI check for changed entries:", paste(changed_entries, collapse=", "), "\n\n")
  } else {
    cat("Running full DOI check for all entries\n\n")
  }

  for (filename in args) {
    if (file.exists(filename)) {
      process_bib_file(filename, changed_entries)
    } else {
      cat("Warning: File not found:", filename, "\n")
    }
  }

  # Summary
  cat("DOI Validation Summary\n")
  cat("=====================\n")
  cat("Total DOI entries checked:", checked_count, "\n")
  cat("Format errors:", format_errors, "\n")
  cat("Duplicate DOIs:", duplicate_count, "\n")
  if (api_available) {
    cat("API errors:", api_error_count, "\n")
    cat("Mismatches found:", mismatch_count, "\n")
  }

  total_errors <- format_errors + duplicate_count + api_error_count + mismatch_count

  if (total_errors > 0) {
    cat("\nSome DOI validation issues were found. Please review the entries above.\n")
    quit(status = 1)
  } else {
    cat("\nAll DOI entries passed validation. Good job!\n")
    quit(status = 0)
  }
}

# Run main function
if (!interactive()) {
  main()
}
