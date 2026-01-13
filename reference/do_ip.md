# Get the URL to a deployed application

Returns the URL to access a deployed application or the droplet's IP
address.

## Usage

``` r
do_ip(droplet, path)
```

## Arguments

- droplet:

  The droplet on which to act.

- path:

  Optional path to append to the IP address. If not provided, just
  returns the IP address.

## Value

A character string with the URL or IP address.
