# Install server dependencies on a droplet

Installs R and common dependencies needed for running \_server.yml
applications. This is called automatically by
[`do_provision()`](https://posit-dev.github.io/buoyant/reference/do_provision.md)
but can be called separately if needed.

## Usage

``` r
do_install_server_deps(droplet, keyfile = do_keyfile())
```

## Arguments

- droplet:

  The DigitalOcean droplet that you want to provision (see
  [`analogsea::droplet()`](https://pacha.dev/analogsea/reference/droplet.html)).
  If empty, a new DigitalOcean server will be created.

- keyfile:

  Path to private key for authentication. By default, uses the key for
  "digitalocean.com" from
  [`ssh::ssh_key_info()`](https://docs.ropensci.org/ssh/reference/ssh_credentials.html).
