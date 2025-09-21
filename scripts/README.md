# DOI Validation Script

This directory contains a script to validate DOI fields in BibTeX entries.

## Scripts

### `doi_check.R`

A comprehensive R script that validates DOI fields in BibTeX files by checking:

1. **DOI Format Validation**: Ensures DOIs follow the standard format (10.xxxx/yyyy)
2. **Duplicate Detection**: Identifies duplicate DOIs across entries
3. **Format Issues**: Detects common problems like URL prefixes, invalid patterns, etc.
4. **API Validation**: When network access is available, validates against CrossRef API and compares metadata

#### Usage

```bash
# Check default files (articles.bib, biblio.bib, crossref.bib)
./scripts/doi_check.R

# Check specific files
./scripts/doi_check.R articles.bib biblio.bib

# Check a single file
./scripts/doi_check.R crossref.bib
```

#### Features

- **Format Validation**: Checks DOI structure against standard patterns
- **Duplicate Detection**: Prevents multiple entries using the same DOI
- **URL Cleaning**: Automatically removes http(s)://doi.org/ prefixes
- **Network-Aware**: Automatically detects if CrossRef API is available
- **Metadata Comparison**: When API is available, compares titles, authors, and years
- **Comprehensive Reporting**: Clear summary of validation results
- **Exit Codes**: Proper exit codes for integration with CI/CD
- **Automatic Package Installation**: Installs required R packages if not available

#### Output Example

```
DOI Validation Script for IRIDIA BibTeX Repository
=================================================

CrossRef API not available - format and duplicate validation only

Processing file: crossref.bib
Checking entry ANTS2016: 10.1007/978-3-319-44427-7
...
Found 41 entries with DOI in crossref.bib

DOI Validation Summary
=====================
Total DOI entries checked: 41
Format errors: 0
Duplicate DOIs: 0

All DOI entries passed validation. Good job!
```

#### Requirements

- `R` with packages: `rbibutils`, `jsonlite`, `httr` (auto-installed if missing)

#### Integration

The script is designed to be integrated into existing testing workflows. It returns:
- Exit code 0: All validations passed
- Exit code 1: Validation errors found

This makes it suitable for use in continuous integration pipelines alongside existing bibliography validation tools.
