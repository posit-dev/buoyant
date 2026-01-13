# Remove a deployed application

Removes a deployed \_server.yml application from the server.

## Usage

``` r
do_remove_server(droplet, path, delete = FALSE, ...)
```

## Arguments

- droplet:

  The droplet on which to act.

- path:

  The path/name of the application to remove.

- delete:

  If `TRUE`, also deletes the application files. If `FALSE`, just stops
  and disables the service.

- ...:

  additional arguments to pass to
  [`analogsea::droplet_ssh()`](https://pacha.dev/analogsea/reference/droplet_ssh.html).

## Value

The DigitalOcean droplet

## Examples

``` r
if (FALSE) { # \dontrun{
  droplet <- analogsea::droplet(123456)

  # Stop the service but keep files
  do_remove_server(droplet, "myapp", delete = FALSE)

  # Remove the service and delete all files
  do_remove_server(droplet, "myapp", delete = TRUE)
} # }
```
