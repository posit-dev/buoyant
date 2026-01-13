# buoyant 0.1.0

Initial release of buoyant - a package for deploying `_server.yml` compliant R web server applications to DigitalOcean.

## Core Features

- Deploy `_server.yml` applications to DigitalOcean droplets
- Validate `_server.yml` files before deployment
- Support for HTTPS/SSL via Let's Encrypt
- Multiple applications on a single server
- Automatic systemd service creation and nginx configuration
- Support for any R web framework implementing the `_server.yml` standard (plumber2, fiery, etc.)

## Functions

### Deployment

- `do_provision()`: Provision a DigitalOcean droplet with R and dependencies
- `do_deploy_server()`: Deploy a `_server.yml` application to a droplet
- `do_remove_server()`: Remove a deployed application from a droplet
- `do_configure_https()`: Add HTTPS support via Let's Encrypt
- `do_forward()`: Forward root path to an application
- `do_remove_forward()`: Remove root path forwarding
- `do_install_server_deps()`: Install server dependencies on a droplet
- `do_keyfile()`: Helper function to manage SSH key authentication
- `do_ip()`: Get the URL to access a deployed application

### Validation

- `validate_server_yml()`: Validate `_server.yml` configuration files
- `read_server_yml()`: Read and parse `_server.yml` configuration

## Documentation

- Comprehensive README with getting started guide and API reference
- Getting started vignette with step-by-step deployment walkthrough
- Advanced usage vignette covering multiple apps, HTTPS, and renv integration
- Troubleshooting vignette with common issues and solutions

## Infrastructure

- GitHub Actions workflow for automated R CMD check
- Code of Conduct and contribution guidelines
- pkgdown website configuration
