# Validate a \_server.yml file

Checks that a `_server.yml` file is properly formatted according to the
\_server.yml standard. This includes verifying that the engine field
exists and that the specified engine package has a `launch_server()`
function.

## Usage

``` r
validate_server_yml(path, check_engine = FALSE, verbose = TRUE)
```

## Arguments

- path:

  Path to the directory containing `_server.yml` or path to the
  `_server.yml` file itself.

- check_engine:

  Logical. If `TRUE`, checks that the engine package is installed and
  has a `launch_server()` function. Default is `FALSE` since the engine
  may not be installed locally but will be on the deployment target.

- verbose:

  Logical. If `TRUE`, prints validation progress messages.

## Value

Invisibly returns `TRUE` if validation passes. Throws an error if
validation fails.

## Details

The validation checks:

- The `_server.yml` file exists

- The file is valid YAML

- The required `engine` field is present and is a character string

- If `check_engine = TRUE`, verifies the engine package is installed and
  has a `launch_server()` function

## Examples

``` r
if (FALSE) { # \dontrun{
# Validate a directory containing _server.yml
validate_server_yml("path/to/api")

# Validate and check that the engine is installed
validate_server_yml("path/to/api", check_engine = TRUE)
} # }
```
