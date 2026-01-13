# Read \_server.yml configuration

Reads and parses a `_server.yml` file, returning the configuration as a
list.

## Usage

``` r
read_server_yml(path)
```

## Arguments

- path:

  Path to the directory containing `_server.yml` or path to the
  `_server.yml` file itself.

## Value

A list containing the parsed YAML configuration.

## Examples

``` r
if (FALSE) { # \dontrun{
config <- read_server_yml("path/to/api")
print(config$engine)
} # }
```
