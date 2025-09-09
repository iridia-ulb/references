# Workflow Documentation

This repository uses a modular workflow system for improved performance, maintainability, and debugging.

## Workflow Overview

The CI/CD pipeline consists of several focused workflows:

### Core Workflows

1. **Validate** (`.github/workflows/validate.yml`)
   - Triggers on push/PR to validate basic syntax
   - Quick BibTeX format checks
   - Sets outputs for other workflows

2. **Test** (`.github/workflows/test.yml`)  
   - Runs comprehensive LaTeX compilation tests
   - Uses matrix strategy for different bibliography styles
   - Caches TeX Live for performance

3. **BibCheck** (`.github/workflows/bibcheck.yml`)
   - R-based bibliography validation
   - Triggers on changes to specific files
   - Validates cross-references and consistency

4. **Lint** (`.github/workflows/lint.yml`)
   - Auto-formats BibTeX files on push to main
   - Commits changes automatically with [skip ci] tag
   - Separate from main workflow to avoid conflicts

5. **Build** (`.github/workflows/build.yml`)
   - Generates PDFs and HTML after tests pass
   - Compresses files for web deployment
   - Uploads artifacts for deployment

6. **Deploy** (`.github/workflows/deploy.yml`)
   - Deploys to GitHub Pages after successful build
   - Uses proper Pages actions for security

### Supporting Workflows

- **PR Check** (`.github/workflows/pr-check.yml`): Validates pull requests
- **Workflow Status** (`.github/workflows/status.yml`): Reports failures and creates issues
- **CI (Legacy)** (`.github/workflows/test-and-deploy.yml`): Backward-compatible PR validation

## Key Improvements

### Performance
- ✅ **Parallel execution**: Independent jobs run simultaneously
- ✅ **Smart caching**: TeX Live and R packages cached effectively  
- ✅ **Conditional execution**: Jobs skip when no relevant changes
- ✅ **Matrix strategy**: Test multiple configurations in parallel

### Maintainability
- ✅ **Separation of concerns**: Each workflow has a single responsibility
- ✅ **Modular design**: Easy to modify individual components
- ✅ **Better error reporting**: Focused logs for easier debugging
- ✅ **Status monitoring**: Automated issue creation for persistent failures

### Developer Experience
- ✅ **Faster feedback**: Quick validation for simple changes
- ✅ **Manual triggers**: `workflow_dispatch` for testing
- ✅ **PR validation**: Comprehensive checks before merge
- ✅ **Auto-formatting**: Consistent code style maintained automatically

### Security & Dependencies
- ✅ **Dependabot**: Automated dependency updates
- ✅ **Minimal permissions**: Each workflow has appropriate access
- ✅ **Modern actions**: Updated to latest versions

## Migration Strategy

The new workflow system is designed to be backward compatible:

1. **Immediate**: All new pushes use the new modular system
2. **Pull Requests**: Continue using enhanced legacy workflow for validation  
3. **Gradual**: Can disable legacy workflow once new system is proven

## Troubleshooting

### Common Issues

1. **Test fails with "fast_check.sh not found"**
   - Ensure you're running from the correct directory
   - Check file permissions: `chmod +x test/fast_check.sh`

2. **TeX Live cache misses frequently**
   - Check if `.github/texlive_packages` changed
   - Increase cache version in workflow environment

3. **Linting creates commit conflicts**
   - Linting runs on separate workflow to avoid conflicts
   - Always includes `[skip ci]` to prevent loops

### Development Workflow

1. **Make changes** to `.bib` files or scripts
2. **Push to branch** - triggers validation and testing
3. **Create PR** - runs comprehensive validation
4. **Merge to main** - triggers full build and deploy pipeline

## Configuration

### Caching
- Cache version: `v2` (increment to invalidate)
- TeX Live cached based on package list hash
- R packages cached with version locking

### Scheduling
- **Dependabot**: Weekly for GitHub Actions, monthly for R
- **Status checks**: Run after each workflow completion  
- **Deploy**: Only on successful builds from main branch

For questions or issues, create an issue with the `workflow` label.