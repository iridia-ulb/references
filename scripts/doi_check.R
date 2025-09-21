#!/usr/bin/env Rscript
#
# DOI Validation Script for IRIDIA BibTeX Repository
# 
# This script checks that DOI fields in BibTeX entries match the correct papers
# by querying the CrossRef API and comparing metadata.
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
error_count <- 0
mismatch_count <- 0

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
  if (is.null(doi) || is.na(doi) || doi == "") return(NULL)
  
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
  
  cat("Checking DOI for entry", bib_key, ":", doi, "\n")
  
  crossref_data <- get_crossref_metadata(doi)
  checked_count <<- checked_count + 1
  
  if (is.null(crossref_data)) {
    error_count <<- error_count + 1
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

# Function to process a single BibTeX file
process_bib_file <- function(filename, macro_files = NULL) {
  cat("Processing file:", filename, "\n")
  
  tryCatch({
    # Read bibliography with macro files
    bibs <- readBib(filename, direct=TRUE, macros=macro_files)
    
    entries_with_doi <- 0
    for (i in 1:length(bibs)) {
      entry <- unclass(bibs[[i]])[[1L]]
      key <- attr(entry, "key")
      
      if (!is.null(entry$doi)) {
        entries_with_doi <- entries_with_doi + 1
        compare_entry_with_crossref(entry, key)
      }
    }
    
    cat("Found", entries_with_doi, "entries with DOI in", filename, "\n\n")
    
  }, error = function(e) {
    cat("Error processing", filename, ":", e$message, "\n\n")
    error_count <<- error_count + 1
  })
}

# Main execution
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  # Default files if none specified
  if (length(args) == 0) {
    args <- c("articles.bib", "biblio.bib", "crossref.bib")
    cat("No files specified, checking default files with DOI entries\n\n")
  }
  
  # Define macro files for parsing
  macro_files <- c("abbrev.bib", "authors.bib", "journals.bib")
  
  cat("DOI Validation Script for IRIDIA BibTeX Repository\n")
  cat("=================================================\n\n")
  
  for (filename in args) {
    if (file.exists(filename)) {
      process_bib_file(filename, macro_files)
    } else {
      cat("Warning: File not found:", filename, "\n")
    }
  }
  
  # Summary
  cat("DOI Validation Summary\n")
  cat("=====================\n")
  cat("Total DOI entries checked:", checked_count, "\n")
  cat("API errors:", error_count, "\n")
  cat("Mismatches found:", mismatch_count, "\n")
  
  if (mismatch_count > 0) {
    cat("\nSome DOI mismatches were found. Please review the entries above.\n")
    quit(status = 1)
  } else {
    cat("\nAll DOI entries appear to match their metadata. Good job!\n")
    quit(status = 0)
  }
}

# Run main function
if (!interactive()) {
  main()
}