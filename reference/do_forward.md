# Forward root requests to an application

Configures nginx to forward requests from the root path (/) to a
specific application.

## Usage

``` r
do_forward(droplet, path, ...)
```

## Arguments

- droplet:

  The droplet on which to act.

- path:

  The application path to forward root requests to.

- ...:

  additional arguments to pass to
  [`analogsea::droplet_ssh()`](https://pacha.dev/analogsea/reference/droplet_ssh.html).
