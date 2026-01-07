# buoyant 0.1.0

Initial release of buoyant - a package for deploying `_server.yml` compliant R web server applications.

## Features

- Deploy `_server.yml` applications to DigitalOcean
- Validate `_server.yml` files before deployment
- Support for HTTPS/SSL via Let's Encrypt
- Multiple applications on a single server
- Automatic systemd service creation and nginx configuration

## Functions

### Deployment
- `do_provision()`: Provision a DigitalOcean droplet
- `do_deploy_server()`: Deploy a `_server.yml` application
- `do_remove_server()`: Remove a deployed application
- `do_configure_https()`: Add HTTPS support
- `do_forward()`: Forward root path to an application
- `do_ip()`: Get application URL

### Validation
- `validate_server_yml()`: Validate `_server.yml` files
- `read_server_yml()`: Read `_server.yml` configuration

## Supported Engines

- plumber2
- fiery
- Any package implementing the `_server.yml` standard
