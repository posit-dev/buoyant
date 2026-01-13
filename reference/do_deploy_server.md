# Deploy or Update a \_server.yml Application

Deploys a \_server.yml-based application from your local machine to make
it available on the remote server.

## Usage

``` r
do_deploy_server(
  droplet,
  path,
  local_file,
  port,
  forward = FALSE,
  overwrite = FALSE,
  ...,
  keyfile = do_keyfile(),
  r_packages = NULL
)
```

## Arguments

- droplet:

  The droplet on which to act. It's expected that this droplet was
  provisioned using
  [`do_provision()`](https://posit-dev.github.io/buoyant/reference/do_provision.md).
  See
  [`analogsea::droplet()`](https://pacha.dev/analogsea/reference/droplet.html)
  to obtain a reference to a running droplet.

- path:

  The remote path/name of the application

- local_file:

  The local file path to a file within a directory containing the
  `_server.yml` file. The parent directory will be deployed.

- port:

  The internal port on which this service should run. This will not be
  visible to visitors, but must be unique and point to a port that is
  available on your server. If unsure, try a number around `8000`.

- forward:

  If `TRUE`, will setup requests targeting the root URL on the server to
  point to this application. See the
  [`do_forward()`](https://posit-dev.github.io/buoyant/reference/do_forward.md)
  function for more details.

- overwrite:

  if an application is already running for this `path` name, and
  `overwrite = TRUE`, then `do_remove_server` will be run.

- ...:

  additional arguments to pass to
  [`analogsea::droplet_ssh()`](https://pacha.dev/analogsea/reference/droplet_ssh.html)
  or
  [`analogsea::droplet_upload()`](https://pacha.dev/analogsea/reference/droplet_ssh.html),
  such as `keyfile`. Cannot contain `remote`, `local` as named
  arguments.

- r_packages:

  A character vector of R packages to install via `{pak}` on the server.
  When `NULL` (default), all dependencies found via `{renv}` will be
  installed.

## Value

The DigitalOcean droplet
