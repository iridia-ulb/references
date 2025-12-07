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
library(cli)
library(rbibutils)
library(jsonlite)
library(httr2)

crossref_whitelist <- scan(what=character(), quiet=TRUE, text='
10.1109/CERMA.2007.60
10.1609/aimag.v17i3.1232
10.2420/AF09.2014.59
10.4230/LIPIcs.CP.2022.35
10.1002/9781118557563
10.2420/AF08.2014.21
')

# Configuration
CROSSREF_API_BASE <- "https://api.crossref.org/works/"
USER_AGENT <- "IRIDIA-BibTeX-Repository/1.0 (mailto:manuel.lopez-ibanez@manchester.ac.uk)"
RATE_LIMIT_DELAY <- 1  # seconds between API calls
MAX_RETRIES <- 3

# Initialize counters
checked_count <- 0L
format_errors <- 0L
duplicate_count <- 0L
doi_org_error_count <- 0L
api_error_count <- 0L
mismatch_count <- 0L

# Global list to track DOI duplicates
# Structure: doi_entries[[doi]] = list(entry_key = "key")
doi_entries <- list()

# Check if CrossRef API is available
api_available <- FALSE
tryCatch({
  # Use a more reliable test - just check if we can connect to the API endpoint
  test_request <- request("https://api.crossref.org/works") |>
    req_headers("User-Agent" = USER_AGENT) |>
    req_timeout(10)
  test_response <- req_perform(test_request)
  api_available <- (resp_status(test_response) %in% c(200, 404))  # 404 is also ok, means API is reachable
}, error = function(e) {
  cat("Warning: api.crossref.org is not reachable. CrossRef checks will be skipped.\n")
  api_available <<- FALSE
})

# Check if doi.org is available
doi_org_available <- FALSE
tryCatch({
  test_request <- request("https://doi.org") |>
    req_timeout(10)
  test_response <- req_perform(test_request)
  doi_org_available <- TRUE
}, error = function(e) {
  doi_org_available <<- FALSE
})

tryCatch_trace <- function(expr, error)
  tryCatch(withCallingHandlers(expr, error = function(e) {
    print(head(sys.calls(), -1))
    signalCondition(e)
  }), error = error)

# Function to check for common DOI format issues
check_doi_issues <- function(doi, entry_key) {
  issue <- NULL
  if (grepl("^https?://", doi, perl = TRUE)) {
    issue <- "Contains URL prefix (should be DOI only)"
  } else if (!grepl("^10\\.[0-9]+/.+", doi, perl = TRUE)) {
    issue <- "DOI should match pattern: 10.xxxx/yyyy where xxxx is registrant code and yyyy is suffix"
  } else if (grepl("[[:space:]]", doi, perl = TRUE)) {
    issue <- "Contains whitespace"
  }

  if (!is.null(issue)) {
    cat("ERROR: Invalid DOI in '", entry_key, "': ", doi, "\n",
      issue, "\n", sep="")
    format_errors <<- format_errors + 1L
    return(FALSE)
  }
  return(TRUE)
}

# Function to track and check for duplicate DOIs
check_duplicate_doi <- function(doi, entry_key) {
  existing_entry <- doi_entries[[doi]]
  if (is.null(existing_entry)) {
    doi_entries[[doi]] <<- list(key = entry_key)
    return(TRUE)
  }
  # Check if this is the same entry (avoid self-duplication)
  if (existing_entry$key == entry_key) {
    # Same entry, just return true (no duplicate)
    return(TRUE)
  }

  # This is a real duplicate
  cat("DUPLICATE DOI found: ", doi, "\n", sep="")
  cat("  First entry: ", existing_entry$key, "\n", sep="")
  cat("  Duplicate entry: ", entry_key, "\n", sep="")
  return(FALSE)
}

# Function to clean and normalize text for comparison
normalize_text <- function(text) {
  if (is.null(text) || is.na(text) || length(text) == 0) return("")
  # Convert to lowercase, remove extra whitespace, punctuation variations
  text <- tolower(as.character(text))
  text <- iconv(text, to='ASCII//TRANSLIT')
  # Remove LaTeX math expressions (everything between dollar signs)
  text <- gsub("\\$[^$]*\\$", "", text, perl = TRUE)
  # LaTeX letters
  text <- gsub("\\\'", "", text, fixed = TRUE)
  text <- gsub('\\\"', "", text, fixed = TRUE)
  text <- gsub('\\c', "", text, fixed = TRUE)

  # Remove LaTeX commands with various argument patterns
  # \command{arg}
  text <- gsub("\\\\[a-zA-Z]+\\{[^}]*\\}", "", text, perl = TRUE)
  # \command[arg]
  text <- gsub("\\\\[a-zA-Z]+\\[[^]]*\\]", "", text, perl = TRUE)
  # \command[arg]{arg1}
  text <- gsub("\\\\[a-zA-Z]+\\[[^]]*\\]\\{[^}]*\\}", "", text, perl = TRUE)
  # Simple \command without arguments
  text <- gsub("\\\\[a-zA-Z]+", "", text, perl = TRUE)
  # Remove braces
  text <- gsub("[{}]", "", text, perl = TRUE)

  # Replace punctuation with spaces
  text <- gsub("[[:punct:]]", " ", text, perl = TRUE)

  # Collapse multiple spaces
  text <- gsub("\\s+", " ", text, perl = TRUE)

  # Trim whitespace
  trimws(text)
}

# Try to extract family name (last part after last comma or space)
extract_family_name <- function(author) {
  author <- trimws(author)
  if (length(author) == 0L)
    return("")
  if (grepl(",", author, fixed = TRUE)) {
    return(strsplit(author, ",")[[1]][1])
  } else if (grepl(" ", author, fixed = TRUE)) {
    parts <- strsplit(author, " ")[[1]]
    return(parts[length(parts)])
  }
  author
}

parse_author_names <- function(authors) {
  if (is.null(authors)) return(NULL)
  if (is.character(authors)) {
    # Simple string parsing for BibTeX authors
    authors <- strsplit(authors, " and ", fixed = TRUE)[[1L]]
  }
  authors <- sapply(authors, function(x) normalize_text(extract_family_name(x$family)))
  unlist(authors[lengths(authors) > 0L])
}

# Function to compare names (handles variations in author formatting)
compare_names <- function(bib_names, crossref_names) {
  if (is.null(bib_names) || is.null(crossref_names)) return(FALSE)
  # Check if there's significant overlap in family names
  if (length(bib_names) == 0L || length(crossref_names) == 0L) return(FALSE)
  overlap <- sum(bib_names %in% crossref_names)
  (overlap >= min(2, min(length(bib_names), length(crossref_names)) * 0.5))
}

# Function to query CrossRef API for DOI metadata
get_crossref_metadata <- function(doi, bib_key = "unknown") {
  if (is.null(doi) || is.na(doi) || doi == "" || !api_available) return(NULL)

  url <- paste0(CROSSREF_API_BASE, doi)

  for (attempt in 1:MAX_RETRIES) {
    tryCatch({
      # Add delay for rate limiting
      Sys.sleep(RATE_LIMIT_DELAY)

      req <- request(url) |>
        req_headers("User-Agent" = USER_AGENT) |>
        req_timeout(30)
      response <- req_perform(req)

      if (resp_status(response) == 200) {
        content <- resp_body_string(response)
        data <- fromJSON(content, simplifyVector = FALSE)
        return(data$message)
      } else if (resp_status(response) == 404) {
        cat("Warning: DOI in '", bib_key, "' not found in CrossRef:", doi, "\n")
        return(NULL)
      } else {
        cat("HTTP", resp_status(response), "for DOI:", doi, "\n")
        if (attempt == MAX_RETRIES) return(NULL)
      }
    }, error = function(e) {
      cli_alert_danger("ERROR: querying DOI {doi} in '{bib_key}' from CrossRef (attempt {attempt}): {e$message}")
      if (attempt == MAX_RETRIES) return(NULL)
    })

    # Exponential backoff for retries
    if (attempt < MAX_RETRIES) Sys.sleep(2^attempt)
  }
  return(NULL)
}

# Function to check if DOI resolves via doi.org REST API
check_doi_resolution <- function(doi) {
  if (is.null(doi) || is.na(doi) || doi == "") return(FALSE)
  if (!doi_org_available) return(TRUE)

  # Try certified query first, then normal query
  for (query_type in c("certified", "normal")) {
    tryCatch({
      # Use doi.org REST API
      base_url <- if (query_type == "certified") {
        "https://doi.org/ra/"
      } else {
        "https://doi.org/api/handles/"
      }

      url <- paste0(base_url, doi)

      req <- request(url) |>
        req_headers("Accept" = "application/json") |>
        req_timeout(30)
      response <- req_perform(req)

      if (resp_status(response) == 200) {
        # Successfully resolved
        return(TRUE)
      }
    }, error = function(e) {
      # Continue to next query type or return FALSE
    })
  }

  # If both certified and normal queries fail, record error
  doi_org_error_count <<- doi_org_error_count + 1L
  return(FALSE)
}

# Function to handle ArXiv DOIs using ArXiv API
validate_arxiv_doi <- function(doi, bib_key) {
  # Check if DOI resolves
  if (!check_doi_resolution(doi)) {
    cat("ERROR: ArXiv DOI in '", bib_key, "' does not resolve:", doi, "\n")
    return(FALSE)
  }
  return(TRUE)
}

# Function to handle Dagstuhl DOIs
validate_dagstuhl_doi <- function(doi, bib_key) {
  # Check if DOI resolves to Dagstuhl
  if (!check_doi_resolution(doi)) {
    cat("ERROR: Dagstuhl DOI in '", bib_key, "' does not resolve:", doi, "\n")
    return(FALSE)
  }
  return(TRUE)
}

# Function to handle Zenodo DOIs
validate_zenodo_doi <- function(doi, bib_key) {
  # Check if DOI resolves to Zenodo
  if (!check_doi_resolution(doi)) {
    cat("ERROR: Zenodo DOI in '", bib_key, "' does not resolve:", doi, "\n")
    return(FALSE)
  }
  return(TRUE)
}

explain_differences <- function(bib_entry, bib_key, crossref_data) {

  # Compare year - prefer published-print over published
  bib_year <- as.character(bib_entry$year)
  # First try published-print, then published
  if (!is.null(crossref_data$`published-print`) && !is.null(crossref_data$`published-print`$`date-parts`)) {
    crossref_year <- as.character(crossref_data$`published-print`$`date-parts`[[1]][1])
  } else if (!is.null(crossref_data$published) && !is.null(crossref_data$published$`date-parts`)) {
    crossref_year <- as.character(crossref_data$published$`date-parts`[[1]][1])
  } else if (!is.null(crossref_data$created) && !is.null(crossref_data$created$`date-parts`)) {
    crossref_year <- as.character(crossref_data$created$`date-parts`[[1]][1])
  } else
    crossref_year <- ""

  year_match <- (bib_year == crossref_year)

  ## Compare titles:
  # When not inherited from a crossref field, prefer booktitle before title.
  if (is.null(bib_entry$crossref) && is.character(bib_entry$booktitle) && bib_entry$booktitle != ""
    && !(tolower(attr(bib_entry, "bibtype")) %in% c("inproceedings", "incollection", "inbook")))
    bib_title <- bib_entry$booktitle
  else
    bib_title <- bib_entry$title

  bib_title <- normalize_text(bib_title)

  crossref_title <- normalize_text(paste0(crossref_data$title, collapse = " "))
  title_match <- FALSE
  if (bib_title != "" && crossref_title != "") {
    # Check if titles have significant overlap (handle variations)
    title_words_bib <- strsplit(bib_title, " ", fixed = TRUE)[[1]]
    title_words_cr <- strsplit(crossref_title, " ", fixed = TRUE)[[1]]
    if (length(title_words_bib) > 0 && length(title_words_cr) > 0) {
      overlap <- sum(title_words_bib %in% title_words_cr)
      title_match <- overlap >= min(3, min(length(title_words_bib), length(title_words_cr)) * 0.6)
    }
  }

  author_match <- TRUE
  if (!year_match || !title_match) {
    # Extract family names from BibTeX
    bib_authors <- bib_entry$author
    bib_names <- parse_author_names(bib_authors)
    # Extract family names from CrossRef JSON
    crossref_authors <- crossref_data$author
    crossref_names <- parse_author_names(crossref_authors)
    # Compare authors
    author_match <- compare_names(bib_names, crossref_names)
  }

  # Overall match assessment: At least 2 out of 3 should match.
  if (sum(title_match, author_match, year_match) >= 2L)
    return(TRUE)

  mismatch_count <<- mismatch_count + 1L
  cat("MISMATCH found in entry", bib_key, "with DOI:", bib_entry$doi, "\n")
  # Only print titles when they don't match
  cat("  Title match:", title_match, "\n")
  if (!title_match) {
    cat(sep="",
      "   BibTeX:'", bib_title, "'\n",
      " CrossRef:'", crossref_title, "'\n",
      "bib$title:'", bib_entry$title, "'\n",
      "bib$booktitle:'", bib_entry$booktitle, "'\n",
      " cr$title:'", paste0(crossref_data$title, collapse = " "), "'\n")
  }

  # Only print authors when they don't match
  cat("  Author match:", author_match, "\n")
  if (!author_match) {
    cat(sep="",
      "   BibTeX:'", paste0(bib_names, collapse="','"), "'\n",
      " CrossRef:'", paste0(crossref_names, collapse="','"), "'\n")
    str(bib_entry$author)
    str(crossref_data$author)
  }
  if (year_match)
    cat("  Year match: TRUE\n\n")
  else
    cat("  Year match: FALSE (", bib_year, "vs", crossref_year, ")\n\n")
  browser()
  return(FALSE)
}

# Function to compare BibTeX entry with CrossRef metadata
compare_entry_with_crossref_api <- function(bib_entry, bib_key) {
  doi <- bib_entry$doi
  # skip whitelisted
  if (is.null(doi) || is.na(doi) || doi == "" || doi %in% crossref_whitelist)
    return(TRUE)

  crossref_data <- get_crossref_metadata(doi, bib_key)
  if (is.null(crossref_data)) {
    api_error_count <<- api_error_count + 1L
    return(FALSE)
  }
  explain_differences(bib_entry, bib_key, crossref_data)
}

# Function to validate a single DOI entry
validate_doi_entry <- function(bib_entry, bib_key, bibs) {
  doi <- bib_entry$doi
  if (is.null(doi) || is.na(doi) || doi == "") return(TRUE)

  checked_count <<- checked_count + 1L
  # Only print checking message if there are problems (will be shown by individual checks)
  if (!check_doi_issues(doi, bib_key))
    return(FALSE)

  crossref_key <- bib_entry$crossref
  if (!is.null(crossref_key) && crossref_key %in% names(bibs)) {
    crossref_entry <- unclass(bibs[[crossref_key]])[[1L]]
    if (!is.null(crossref_entry$doi) && doi == crossref_entry$doi)
      return(TRUE)
  }

  # Check for duplicates with crossref awareness
  if (!check_duplicate_doi(doi, bib_key))
    return(FALSE)

  # Handle different types of DOIs
  api_ok <- TRUE
  doi_lower <- tolower(doi)
  # Determine DOI type and handle accordingly
  if (startsWith(doi_lower, "10.48550/arxiv")) {
    # ArXiv DOI - use ArXiv API or just check resolution
    api_ok <- validate_arxiv_doi(doi, bib_key)
  } else if (startsWith(doi_lower, "10.4230/dagrep")) {
    # Dagstuhl DOI - check resolution to Dagstuhl
    api_ok <- validate_dagstuhl_doi(doi, bib_key)
  } else if (startsWith(doi_lower, "10.5281/zenodo")) {
    # Zenodo DOI - check resolution to Zenodo
    api_ok <- validate_zenodo_doi(doi, bib_key)
  } else {
    # Check if DOI resolves
    if (!check_doi_resolution(doi)) {
      cat("ERROR: DOI in '", bib_key, "' does not resolve via doi.org:", doi, "\n")
      return(FALSE)
    }
    if (api_available) {
      # Regular DOI - try CrossRef API validation
      api_ok <- compare_entry_with_crossref_api(bib_entry, bib_key)
    }
  }
  # Return status based on validations
  return(api_ok)
}

# Function to process a single BibTeX file
process_bib_file <- function(filename, changed_entries = NULL) {
  cat("Processing file:", filename, "\n")
  # Define macro files for parsing
  if (endsWith(filename, "biblio.bib"))
    macro_files <- c("abbrev.bib", "authors.bib", "journals.bib", "crossref.bib")
  else if (endsWith(filename, "crossref.bib"))
    macro_files <- c("abbrev.bib", "authors.bib")
  else if (endsWith(filename, "articles.bib"))
    macro_files <- c("abbrev.bib", "authors.bib", "journals.bib")
  else
    macro_files <- NULL

  tryCatch_trace({
    # Read bibliography with macro files
    bibs <- readBib(filename, direct=TRUE, macros=macro_files)

    entries_with_doi <- 0
    entries_checked <- 0

    if (is.null(changed_entries)) {
      for (i in cli_progress_along(bibs, "Processing DOIs")) {
        entry <- unclass(bibs[[i]])[[1L]]
        key <- attr(entry, "key")
        if (!is.null(entry$doi)) {
          entries_with_doi <- entries_with_doi + 1L
          validate_doi_entry(entry, key, bibs)
          entries_checked <- entries_checked + 1L
        }
      }
    } else {
      changed_entries_in_bib <- intersect(changed_entries, names(bibs))
      for (key in changed_entries_in_bib) {
        entry <- unclass(bibs[[key]])[[1L]]
        if (!is.null(entry$doi)) {
          entries_with_doi <- entries_with_doi + 1L
          validate_doi_entry(entry, key, bibs)
          entries_checked <- entries_checked + 1L
        }
      }
    }
    cat("Checked", entries_checked, "entries with DOI in", filename, "\n\n")

  }, error = function(e) {
    cat("Error processing", filename, ":", e$message, "\n\n")
    api_error_count <<- api_error_count + 1L
  })
}

# Main execution
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  # Parse arguments for changed entries
  changed_entries <- NULL
  changed_entries_flag <- which(args == "--changed-entries")
  if (length(changed_entries_flag) > 0 && length(args) > changed_entries_flag) {
    changed_entries_str <- args[changed_entries_flag + 1L]
    changed_entries <- trimws(strsplit(changed_entries_str, " ")[[1L]])
    changed_entries <- changed_entries[changed_entries != ""]
    # Remove the flag and entries from args
    args <- args[-c(changed_entries_flag, changed_entries_flag + 1L)]
  }

  cat(sep="\n",
    "DOI Validation Script for IRIDIA BibTeX Repository",
    "==================================================\n")

  # Default files if none specified
  if (length(args) == 0L) {
    args <- c("articles.bib", "biblio.bib", "crossref.bib")
    if (is.null(changed_entries)) {
      cat("No files specified, checking default files with DOI entries\n\n")
    }
  }

  # Report API availability
  if (api_available) {
    cat("CrossRef API is available - full validation enabled\n")
  } else {
    cat("Warning: CrossRef API not available - format and duplicate validation only\n")
  }
  if (doi_org_available) {
    cat("doi.org API is available - full doi resolution enabled\n")
  } else {
    cat("Warning: doi.org is not reachable. DOI resolution checks will be skipped.\n")
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
  cli_h2("DOI Validation Summary")
  cli_ul(c(
    "Total DOI entries checked: {checked_count}",
    "Format errors: {format_errors}",
    "Duplicate DOIs: {duplicate_count}"))
  if (doi_org_available) {
    cli_ul("DOI resolution errors: {doi_org_error_count}\n")
  }
  if (api_available) {
    cli_ul(c(
      "API errors: {api_error_count}",
      "Mismatches found: {mismatch_count}"))
  }

  total_errors <- format_errors + duplicate_count + api_error_count + mismatch_count + doi_org_error_count

  if (total_errors > 0) {
    cli_alert_danger("\nSome DOI validation issues were found. Please review the entries above.\n")
    quit(status = 1)
  } else {
    cli_alert_success("\nAll DOI entries passed validation. Good job!\n")
    quit(status = 0)
  }
}

# Run main function
if (!interactive()) {
  main()
}
process_bib_file("crossref.bib")
