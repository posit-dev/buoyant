# Get the default DigitalOcean SSH keyfile path

Returns the path to the SSH private key for "digitalocean.com" from
[`ssh::ssh_key_info()`](https://docs.ropensci.org/ssh/reference/ssh_credentials.html).
This is used as the default keyfile for all buoyant functions that
interact with DigitalOcean droplets.

## Usage

``` r
do_keyfile()
```

## Value

A character string with the path to the SSH private key, or NULL if no
key is found.

## Examples

``` r
if (FALSE) { # \dontrun{
  # Get the default keyfile path
  do_keyfile()
} # }
```
