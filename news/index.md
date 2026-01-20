# Changelog

## buoyant 0.1.0

CRAN release: 2026-01-19

Initial release of [buoyant](https://posit-dev.github.io/buoyant/):
Deploy ’\_server.yml’ Compliant Applications to ‘DigitalOcean’.

### New features

- [`do_configure_https()`](https://posit-dev.github.io/buoyant/reference/do_configure_https.md)
  adds HTTPS support via Let’s Encrypt.

- [`do_deploy_server()`](https://posit-dev.github.io/buoyant/reference/do_deploy_server.md)
  deploys a `_server.yml` application to a droplet with automatic
  systemd service creation and nginx configuration. Multiple
  applications can be deployed to a single server.

- [`do_forward()`](https://posit-dev.github.io/buoyant/reference/do_forward.md)
  forwards root path to an application.

- [`do_install_server_deps()`](https://posit-dev.github.io/buoyant/reference/do_install_server_deps.md)
  installs server dependencies on a droplet.

- [`do_ip()`](https://posit-dev.github.io/buoyant/reference/do_ip.md)
  gets the URL to access a deployed application.

- [`do_keyfile()`](https://posit-dev.github.io/buoyant/reference/do_keyfile.md)
  manages SSH key authentication.

- [`do_provision()`](https://posit-dev.github.io/buoyant/reference/do_provision.md)
  provisions a DigitalOcean droplet with R and dependencies.

- [`do_remove_forward()`](https://posit-dev.github.io/buoyant/reference/do_remove_forward.md)
  removes root path forwarding.

- [`do_remove_server()`](https://posit-dev.github.io/buoyant/reference/do_remove_server.md)
  removes a deployed application from a droplet.

- [`read_server_yml()`](https://posit-dev.github.io/buoyant/reference/read_server_yml.md)
  reads and parses `_server.yml` configuration files.

- [`validate_server_yml()`](https://posit-dev.github.io/buoyant/reference/validate_server_yml.md)
  validates `_server.yml` configuration files before deployment.
