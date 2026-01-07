# buoyant

> Deploy `_server.yml` Compliant Applications

## Overview

`buoyant` is an R package for deploying web server applications that follow the [`_server.yml` standard](https://plumber2.posit.co/articles/server_yml.html). This standard provides a unified way to specify and deploy R web servers regardless of the underlying framework (plumber2, fiery, etc.).

The package is inspired by [plumberDeploy](https://github.com/meztez/plumberDeploy) and extends its concepts to support any `_server.yml`-compliant application.

## Installation

```r
# Install from GitHub (once available)
# remotes::install_github("rstudio/buoyant")

# For now, install from source
devtools::load_all("path/to/buoyant")
```

## The `_server.yml` Standard

The `_server.yml` standard is a lightweight specification for R web servers. The only requirement is an `engine` field that specifies which R package will run the server:

```yaml
engine: plumber2
```

Each engine package (like `plumber2` or `fiery`) can define additional fields specific to their needs. The engine must provide a `launch_server(settings, host = NULL, port = NULL, ...)` function that accepts:

- `settings`: Path to the `_server.yml` file
- `host`: IP address to bind to
- `port`: Port number to listen on
- `...`: Additional arguments

## Features

- **Deploy to DigitalOcean**: Provision droplets and deploy `_server.yml` compliant applications
- **Validation**: Validate `_server.yml` files before deployment

## Quick Start

### Validate Your Application

```r
library(buoyant)

# Validate the _server.yml file in your application directory
validate_server_yml("path/to/my-api")
```

### Deploy to DigitalOcean

```r
library(buoyant)
library(analogsea)

# Authenticate with DigitalOcean
do_oauth()

# Provision a new server (this costs money!)
droplet <- do_provision(region = "sfo3")

# Deploy your application
do_deploy_server(
  droplet = droplet,
  path = "myapp",
  localPath = "path/to/my-api",
  port = 8000,
  forward = TRUE
)

# Get the URL
do_ip(droplet, "/myapp")
# Visit http://<ip-address>/myapp

# Add HTTPS (optional, requires a domain)
do_configure_https(
  droplet = droplet,
  domain = "api.example.com",
  email = "you@example.com",
  termsOfService = TRUE
)
```

### Remove a Deployment

```r
# Stop the service and optionally delete files
do_remove_server(droplet, path = "myapp", delete = TRUE)
```

## Validation

Before deploying, you can validate your `_server.yml` file:

```r
# Basic validation (checks file structure)
validate_server_yml("path/to/app")

# Validate and check that the engine is installed locally
validate_server_yml("path/to/app", check_engine = TRUE)

# Read the configuration
config <- read_server_yml("path/to/app")
print(config$engine)
```

## Supported Engines

The following R packages support the `_server.yml` standard:

- [plumber2](https://plumber2.posit.co)
- [fiery](https://fiery.data-imaginist.com)

To make your own package compatible, see the [_server.yml specification](https://plumber2.posit.co/articles/server_yml.html).

## Function Reference

### Deployment Functions

- `do_provision()`: Create and configure a DigitalOcean droplet
- `do_deploy_server()`: Deploy a `_server.yml` application
- `do_remove_server()`: Remove a deployed application
- `do_configure_https()`: Add HTTPS/SSL support
- `do_forward()`: Forward root path to an application
- `do_remove_forward()`: Remove root path forwarding
- `do_ip()`: Get the URL to access a deployed application

### Validation Functions

- `validate_server_yml()`: Validate a `_server.yml` file
- `read_server_yml()`: Read and parse a `_server.yml` file

## Example: Complete Deployment Workflow

```r
library(buoyant)
library(analogsea)

# 1. Validate your application locally
validate_server_yml("my-api", check_engine = TRUE)

# 2. Set up DigitalOcean authentication
do_oauth()

# 3. Provision a server
droplet <- do_provision(region = "sfo3")

# 4. Deploy your application
do_deploy_server(
  droplet = droplet,
  path = "api",
  localPath = "my-api",
  port = 8000,
  forward = TRUE  # Make it accessible at root path
)

# 5. Visit your API
url <- do_ip(droplet, "/api")
browseURL(url)

# 6. When you're done (this deletes the server)
droplet_delete(droplet)
```

## Advanced Usage

### Multiple Applications on One Server

You can deploy multiple `_server.yml` applications to the same droplet:

```r
# Deploy first app
do_deploy_server(droplet, "app1", "path/to/app1", port = 8000)

# Deploy second app (use a different port!)
do_deploy_server(droplet, "app2", "path/to/app2", port = 8001)

# Access them at:
# http://<ip>/app1
# http://<ip>/app2
```

### Custom DigitalOcean Configuration

```r
# Provision with custom size and region
droplet <- do_provision(
  size = "s-2vcpu-4gb",
  region = "nyc3",
  name = "my-production-server"
)
```

### Working with Existing Droplets

```r
# Get a reference to an existing droplet
droplet <- droplet(id = 12345678)

# Or by name
droplet <- droplets() %>%
  purrr::keep(~ .x$name == "my-server") %>%
  purrr::pluck(1)

# Deploy to it
do_deploy_server(droplet, "newapp", "path/to/app", port = 8002)
```

## How It Works

When you deploy a `_server.yml` application with `buoyant`:

1. **Upload**: Your application directory is uploaded to `/var/server-apps/<path>/` on the droplet
2. **Install Engine**: The engine package specified in `_server.yml` is installed if not present
3. **Create Service**: A systemd service is created to run your application with auto-restart
4. **Configure Nginx**: Nginx is configured to proxy requests to your application
5. **Start**: The service is started and enabled to run on boot

The systemd service runs a command like:

```r
Rscript -e "
  engine <- yaml::read_yaml('_server.yml')$engine
  launch_server <- get('launch_server', envir = asNamespace(engine), mode = 'function')
  launch_server('_server.yml', host = '127.0.0.1', port = 8000)
"
```

This follows the `_server.yml` standard and allows any compliant engine to be deployed the same way.

## Comparison with plumberDeploy

`buoyant` is inspired by `plumberDeploy` but differs in key ways:

- **Framework Agnostic**: Works with any `_server.yml`-compliant engine
- **Standardized**: Uses the `_server.yml` standard for configuration
- **Modern**: Built for newer R server frameworks like plumber2 and fiery
- **Focused**: Currently supports DigitalOcean; other platforms may be added later

## Requirements

- R >= 3.0.0
- DigitalOcean account (for deployment)
- SSH keys configured ([see analogsea documentation](https://github.com/sckott/analogsea))

## Contributing

Contributions are welcome! Please file issues and pull requests on GitHub.

## License

MIT License. See LICENSE.md for details.

## Related Projects

- [analogsea](https://github.com/sckott/analogsea) - R client for DigitalOcean
- [plumber2](https://plumber2.posit.co) - Modern R API framework
- [fiery](https://fiery.data-imaginist.com) - Flexible web server framework

## Acknowledgments

This package is inspired by [plumberDeploy](https://github.com/meztez/plumberDeploy) (an R package to deploy [plumber](https://www.rplumber.io) APIs) maintained by [Bruno Tremblay](https://github.com/meztez/) and originally developed by Jeff Allen.
