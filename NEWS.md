# buoyant (development version)

# buoyant 0.1.0

Initial release of `{buoyant}`: Deploy '_server.yml' Compliant Applications to 'DigitalOcean'.

## New features

* `do_configure_https()` adds HTTPS support via Let's Encrypt.

* `do_deploy_server()` deploys a `_server.yml` application to a droplet with automatic systemd service creation and nginx configuration. Multiple applications can be deployed to a single server.

* `do_forward()` forwards root path to an application.

* `do_install_server_deps()` installs server dependencies on a droplet.

* `do_ip()` gets the URL to access a deployed application.

* `do_keyfile()` manages SSH key authentication.

* `do_provision()` provisions a DigitalOcean droplet with R and dependencies.

* `do_remove_forward()` removes root path forwarding.

* `do_remove_server()` removes a deployed application from a droplet.

* `read_server_yml()` reads and parses `_server.yml` configuration files.

* `validate_server_yml()` validates `_server.yml` configuration files before deployment.
