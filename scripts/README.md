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

#### Requirements

- `R` with packages: `rbibutils`, `jsonlite`, `httr2`

#### Integration

The script is designed to be integrated into existing testing workflows. It returns:
- Exit code 0: All validations passed
- Exit code 1: Validation errors found

This makes it suitable for use in continuous integration pipelines alongside existing bibliography validation tools.

## URL checker

`check-bib-urls` checks the URLs and DOIs in `.bib` files lightly and politely:
it only sends HTTP `HEAD` requests (falling back to a 1-byte ranged `GET`),
never downloads the targets, and waits between requests to the same host.
DOIs are checked via `https://doi.org/api/handles/<doi>`, so publisher sites are not contacted.

```bash
# Stand-alone, whole files (default: all tracked .bib files)
scripts/check-bib-urls articles.bib
pre-commit run check-bib-urls --all-files

# Only lines added in the staged diff (what the pre-commit hook does)
scripts/check-bib-urls --staged
```

Options: `--staged`, `--strict`, `--no-cache`, `--list` (print extracted URLs, no network).
The per-host delay (2 s), the number of parallel hosts (4) and the ignore file name (`.urlignore`)
are set at the top of the script.

- `.urlignore` (repository root): glob patterns (one per line, `#` for comments) of URLs/DOIs to skip.
- Cache: URLs found OK are remembered for 7 days in `~/.cache/bib-url-check`.
- By default only 404/410 fail; other problems (network errors, 5xx, 429) are warnings,
  and `--strict` makes them fail too. 202/401/403 are ignored, as CRAN does.
- Requires bash >= 4.3 (the macOS default bash 3.2 is too old).
- Offline self-check: `test/test-check-bib-urls.sh`.
