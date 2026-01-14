# buoyant

> Deploy `_server.yml` Compliant Applications to DigitalOcean

## Overview

`buoyant` is an R package for deploying web server applications that
follow the [`_server.yml`
standard](https://plumber2.posit.co/articles/server_yml.html) to
DigitalOcean. This standard provides a unified way to specify and deploy
R web servers regardless of the underlying framework (plumber2, fiery,
etc.).

## Installation

You can install the development version of buoyant from
[GitHub](https://github.com/) with:

``` r

# install.packages("pak")
pak::pak("posit-dev/buoyant")
```

## Usage

### Basic Deployment

``` r

library(buoyant)
library(analogsea)

# Authenticate with DigitalOcean
do_oauth()

# Provision a new server
droplet <- do_provision(region = "sfo3")

# Deploy your application
do_deploy_server(
  droplet = droplet,
  path = "myapp",
  local_path = "path/to/my-api",
  port = 8000
)

# Get the URL
do_ip(droplet, "/myapp")
```

### The `_server.yml` Standard

The `_server.yml` standard is a lightweight specification for R web
servers. At minimum, you need an `engine` field:

``` yaml
engine: plumber2
```

Each engine package (like `plumber2` or `fiery`) can define additional
fields. The engine R package must provide a
`launch_server(settings, host = NULL, port = NULL, ...)` function.

## Features

- **Framework Agnostic**: Works with any `_server.yml`-compliant engine
- **Easy Deployment**: One function call to deploy an application -
  [`do_deploy_server()`](https://posit-dev.github.io/buoyant/reference/do_deploy_server.md)
- **Automatic Setup**: Creates systemd services and nginx configuration
- **HTTPS Support**: Easy Let’s Encrypt integration via
  [`do_configure_https()`](https://posit-dev.github.io/buoyant/reference/do_configure_https.md)
- **Multiple Apps**: Deploy multiple applications to one server
- **Validation**: Validate configurations before deployment with
  [`validate_server_yml()`](https://posit-dev.github.io/buoyant/reference/validate_server_yml.md)

## Getting Help

- See the [Getting Started
  vignette](https://posit-dev.github.io/buoyant/vignettes/buoyant.qmd)
  for a complete tutorial
- Browse the [function
  reference](https://posit-dev.github.io/buoyant/reference/) for
  detailed documentation
- Report bugs at <https://github.com/posit-dev/buoyant/issues>

## Supported Engines

The following R packages support the `_server.yml` standard:

- [plumber2](https://plumber2.posit.co)
- [fiery](https://fiery.data-imaginist.com)

To make your own package compatible, see the [\_server.yml
specification](https://plumber2.posit.co/articles/server_yml.html).

## Acknowledgments

This package is inspired by
[plumberDeploy](https://github.com/meztez/plumberDeploy) by Bruno
Tremblay and Jeff Allen. The `_server.yml` standard was developed as
part of the [plumber2](https://plumber2.posit.co) project.
