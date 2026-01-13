# Provision a DigitalOcean server for \_server.yml applications

Create (if required), install the necessary prerequisites, and deploy a
\_server.yml-based R server application on a DigitalOcean virtual
machine. You may sign up for a Digital Ocean account
[here](https://m.do.co/c/6119f0430dad). You should configure an account
ssh key with
[`analogsea::key_create()`](https://pacha.dev/analogsea/reference/key-crud.html)
prior to using this method. This command is idempotent, so feel free to
run it on a single server multiple times.

## Usage

``` r
do_provision(droplet, ..., keyfile = do_keyfile())
```

## Arguments

- droplet:

  The DigitalOcean droplet that you want to provision (see
  [`analogsea::droplet()`](https://pacha.dev/analogsea/reference/droplet.html)).
  If empty, a new DigitalOcean server will be created.

- ...:

  Arguments passed into the
  [`analogsea::droplet_create()`](https://pacha.dev/analogsea/reference/droplet_create.html)
  function.

- keyfile:

  Path to private key for authentication. By default, uses the key for
  "digitalocean.com" from
  [`ssh::ssh_key_info()`](https://docs.ropensci.org/ssh/reference/ssh_credentials.html).

## Value

The DigitalOcean droplet

## Details

Provisions a Ubuntu 24.04-x64 droplet with the following customizations:

- A recent version of R installed

- Common server dependencies installed

- Directory structure at `/var/server-apps` for deployed applications

- The `nginx` web server installed to route web traffic from port 80
  (HTTP)

- `ufw` installed as a firewall to restrict access on the server. By
  default it only allows incoming traffic on port 22 (SSH) and port 80
  (HTTP).

- A 4GB swap file is created to ensure that machines with little RAM
  (the default) are able to get through the necessary R package
  compilations.

## Note

Please see <https://github.com/pachadotdev/analogsea/issues/205> in case
of an error by default `do_provision` and an error of
`"Error: Size is not available in this region."`.

## Examples

``` r
if (FALSE) { # \dontrun{
  auth <- analogsea::do_oauth()

  analogsea::droplets()
  droplet <- do_provision(region = "sfo3")
  analogsea::droplets()

  # Deploy a _server.yml application
  do_deploy_server(
    droplet,
    "myapp",
    "local/path/to/app/",
    port=8000,
    forward=TRUE
  )
  if (interactive()) {
    utils::browseURL(do_ip(droplet, "/myapp"))
  }

  analogsea::droplet_delete(droplet)
} # }
```
