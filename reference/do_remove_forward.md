# Remove root forwarding

Removes any root path forwarding configuration.

## Usage

``` r
do_remove_forward(droplet, ...)
```

## Arguments

- droplet:

  The droplet on which to act.

- ...:

  additional arguments to pass to
  [`analogsea::droplet_ssh()`](https://pacha.dev/analogsea/reference/droplet_ssh.html).

## Value

This function currently stops with an error. Not yet implemented.

## Examples

``` r
if (FALSE) { # \dontrun{
  droplet <- analogsea::droplet(123456)

  # This function is not yet implemented
  do_remove_forward(droplet)
} # }
```
