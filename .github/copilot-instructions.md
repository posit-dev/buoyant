# GitHub Copilot Instructions for buoyant

The buoyant package provides tools for deploying `_server.yml` compliant web applications to DigitalOcean. It supports any R web framework that implements the `_server.yml` standard (plumber2, fiery, etc.). This R package follows standard R package development practices using the devtools ecosystem.

**CRITICAL: Always follow these instructions first and only fallback to additional search and context gathering if the information in these instructions is incomplete or found to be in error.**

## Working Effectively

### Essential Setup Commands

Install required R and development dependencies:

```bash
# Install R if not available (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y r-base r-base-dev build-essential libcurl4-openssl-dev libssl-dev libxml2-dev libssh2-1-dev

# Install core R packages via apt (faster than CRAN for basic packages)
sudo apt-get install -y r-cran-yaml r-cran-jsonlite r-cran-lifecycle r-cran-testthat

# Install additional development packages if available via apt
sudo apt-get install -y r-cran-devtools r-cran-knitr r-cran-rmarkdown

# If packages not available via apt, install via CRAN (may fail if network restricted)
sudo R -e "install.packages(c('analogsea', 'ssh', 'devtools', 'pkgdown'), repos='https://cloud.r-project.org/')"
```

### Build and Development Commands

Always run these commands from the package root directory:

```bash
# Install package from source (basic development workflow)
# TIMING: ~3-5 seconds
sudo R -e "install.packages('.', type = 'source', repos = NULL)"

# Generate documentation from roxygen2 comments (if devtools available)
R -e "devtools::document()"

# Build source package without vignettes (fastest option)
# TIMING: ~0.3 seconds - VERY FAST
R CMD build --no-build-vignettes .

# Basic R CMD check (without tests/vignettes to avoid missing dependencies)
# TIMING: ~12-15 seconds - NEVER CANCEL, Set timeout to 30+ seconds
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-vignettes --no-tests buoyant_*.tar.gz

# Full R CMD check with devtools (if available)
# NEVER CANCEL: Takes 5-15 minutes with all dependencies. Set timeout to 20+ minutes.
R -e "devtools::check()"

# Run unit tests directly from source
# TIMING: ~5-8 seconds - NEVER CANCEL, Set timeout to 30+ seconds
R -e "library(testthat); library(buoyant); test_dir('tests/testthat')"

# Run unit tests using devtools (if available)
R -e "devtools::test()"
```

### Testing Commands

```bash
# Run full test suite from source directory
# TIMING: ~5-8 seconds - NEVER CANCEL, Set timeout to 30+ seconds
R -e "library(testthat); library(buoyant); test_dir('tests/testthat')"

# Run single test file
R -e "library(testthat); library(buoyant); test_file('tests/testthat/test-validate.R')"

# Check if package loads correctly
R -e "library(buoyant)"
```

### Documentation Commands

```bash
# Build package documentation website (if pkgdown available)
# NEVER CANCEL: Takes 3-8 minutes. Set timeout to 15+ minutes.
R -e "pkgdown::build_site()"

# Render vignette (if knitr/rmarkdown available)
R -e "rmarkdown::render('vignettes/buoyant.qmd')"
```

## Validation Requirements

### Always Test These Scenarios After Making Changes:

1. **Basic Package Loading**: Verify the package loads without errors

   ```r
   library(buoyant)
   # Should load successfully with all dependencies
   ```

2. **Validation Functions**: Test \_server.yml validation

   ```r
   library(buoyant)
   # Test validation on a valid _server.yml file
   validate_server_yml("path/to/app")
   ```

3. **Integration Testing**: Verify core dependencies work together
   ```r
   library(analogsea)
   library(ssh)
   library(yaml)
   library(jsonlite)
   library(buoyant)
   # All should load without conflicts
   ```

### Mandatory Pre-Commit Checks:

**CRITICAL**: Run these validation steps before committing any changes:

```bash
# 1. Build package to check for syntax/dependency errors
# TIMING: ~0.3 seconds - VERY FAST
R CMD build --no-build-vignettes .

# 2. Install package to verify it works
# TIMING: ~3-5 seconds
sudo R -e "install.packages('.', type = 'source', repos = NULL)"

# 3. Test package loading
# TIMING: ~1-2 seconds
R -e "library(buoyant)"

# 4. Run test suite if testthat is available
# TIMING: ~5-8 seconds - NEVER CANCEL
R -e "library(testthat); library(buoyant); test_dir('tests/testthat')"

# 5. Full check if time permits (optional but recommended)
# TIMING: ~12-15 seconds - NEVER CANCEL, Set timeout to 30+ seconds
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-vignettes --no-tests buoyant_*.tar.gz
```

**Expected timing summary**:

- Basic build: ~0.3 seconds - **INSTANT**
- Package install: ~3-5 seconds - **VERY FAST**
- Test suite: ~5-8 seconds - **NEVER CANCEL, timeout 30+ seconds**
- Basic check: ~12-15 seconds - **NEVER CANCEL, timeout 30+ seconds**
- Full devtools::check(): 5-15 minutes - **NEVER CANCEL, timeout 20+ minutes**

## Repository Structure

### Core Development Files:

- `R/` - Main R source code (validate.R, digital-ocean.R, utils.R)
- `tests/testthat/` - Unit tests using testthat framework
- `vignettes/` - Package documentation (buoyant.qmd)
- `inst/server/` - Server configuration templates (nginx.conf, nginx-ssl.conf)
- `man/` - Generated documentation (do not edit manually)

### Key Architecture Components:

- **Validation Functions** (`R/validate.R`): \_server.yml validation and parsing
- **Deployment Functions** (`R/digital-ocean.R`): DigitalOcean provisioning and deployment
- **Utility Functions** (`R/utils.R`): Helper functions and internal utilities

### Dependencies (Auto-installed via devtools):

- **Core**: analogsea (>= 0.9.4), ssh, yaml, jsonlite, lifecycle
- **Development**: testthat, devtools, knitr, rmarkdown

## Package Functionality

### Core Deployment Workflow:

1. User creates `_server.yml` compliant application locally
2. User validates `_server.yml` with `validate_server_yml()`
3. User provisions DigitalOcean droplet with `do_provision()`
4. Package uploads files to `/var/server-apps/<path>/`
5. Package installs engine package (plumber2, fiery, etc.)
6. Package creates systemd service that runs `launch_server()`
7. Package configures nginx reverse proxy
8. Application is accessible via `do_ip(droplet, "/path")`

### Supported Engines:

The package works with any R package that implements the `_server.yml` standard:

- **plumber2**: Modern plumber API framework
- **fiery**: Flexible web server framework
- Any custom engine implementing `launch_server()` function

### Configuration Standard:

The `_server.yml` file must include:

- `engine`: Package name implementing launch_server()

## Common Development Tasks

### Adding New Functions:

1. Add function to appropriate R file in `R/` directory
2. Document with roxygen2 comments (use `@export` if public)
3. Run `devtools::document()` to update NAMESPACE and man pages
4. Add tests in `tests/testthat/test-[function-area].R`
5. Run `devtools::test()` to verify tests pass
6. Run `devtools::check()` for full validation

### Working with Nginx Configs:

The package includes nginx configuration templates in `inst/server/`:

- `nginx.conf`: HTTP reverse proxy configuration
- `nginx-ssl.conf`: HTTPS configuration with Let's Encrypt

These are deployed by `do_deploy_server()` and `do_configure_https()`.

## Troubleshooting

### Common Issues:

- **Missing Dependencies**: Install core packages via apt first, then try CRAN for others
  ```bash
  sudo apt-get install -y r-cran-yaml r-cran-jsonlite r-cran-testthat
  # analogsea and ssh need to be installed from CRAN
  sudo R -e "install.packages(c('analogsea', 'ssh'), repos='https://cloud.r-project.org/')"
  ```
- **Package Won't Load**: Reinstall from source: `sudo R -e "install.packages('.', type = 'source', repos = NULL)"`
- **devtools Not Available**: Use R CMD directly for basic operations
- **Test Failures**: Ensure package is installed: tests need the package loaded
- **Build Failures**: Check DESCRIPTION file dependencies match actual imports

### Alternative Commands When devtools Unavailable:

```bash
# Use R CMD instead of devtools equivalents:
R CMD build --no-build-vignettes .                    # instead of devtools::build()
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-vignettes --no-tests *.tar.gz  # instead of devtools::check()
R -e "library(testthat); test_dir('tests/testthat')"  # instead of devtools::test()
sudo R -e "install.packages('.', type='source', repos=NULL)"  # instead of devtools::install()
```

### Network/CRAN Issues:

If CRAN mirrors are unavailable, use apt packages or local installation:

```bash
# Prefer apt packages over CRAN when possible
sudo apt-cache search r-cran- | grep <package_name>

# Force local installation without network
sudo R -e "install.packages('.', type='source', repos=NULL)"
```

### DigitalOcean Authentication:

The package uses `analogsea` for DigitalOcean API access:

```r
# Set up authentication
library(analogsea)
do_oauth()  # Opens browser for authentication

# Or use API token
Sys.setenv(DO_PAT = "your_token_here")
```

## Important Files Reference

### Repository Structure:

- **Root**: `.Rbuildignore`, `.github/`, `.gitignore`, `CLAUDE.md`, `DESCRIPTION`, `LICENSE`, `LICENSE.md`, `NAMESPACE`, `NEWS.md`, `R/`, `README.md`, `buoyant.Rproj`, `inst/`, `man/`, `tests/`, `vignettes/`

### R Source Files (`R/` directory):

- `validate.R` - \_server.yml validation and parsing functions
- `digital-ocean.R` - DigitalOcean deployment and provisioning functions
- `utils.R` - Utility functions and helpers

### Test Files (`tests/testthat/` directory):

- `test-validate.R` - Tests for validation functions

### Server Configuration Files (`inst/server/` directory):

- `nginx.conf` - HTTP reverse proxy configuration
- `nginx-ssl.conf` - HTTPS configuration with SSL

**Remember**: This is a deployment package that interacts with external services (DigitalOcean) and modifies remote servers. Always consider security implications, API rate limits, and proper error handling when making changes. Test deployment functions carefully in isolated environments.
