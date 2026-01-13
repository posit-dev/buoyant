#' Provision a DigitalOcean server for _server.yml applications
#'
#' Create (if required), install the necessary prerequisites, and
#' deploy a _server.yml-based R server application on a DigitalOcean virtual machine.
#' You may sign up for a Digital Ocean account
#' [here](https://m.do.co/c/6119f0430dad).
#' You should configure an account ssh key with [analogsea::key_create()] prior to using this method.
#' This command is idempotent, so feel free to run it on a single server multiple times.
#'
#' @param droplet The DigitalOcean droplet that you want to provision
#'   (see [analogsea::droplet()]). If empty, a new DigitalOcean server will be created.
#' @param ... Arguments passed into the [analogsea::droplet_create()] function.
#' @param keyfile Path to private key for authentication. By default, uses the
#'   key for "digitalocean.com" from [ssh::ssh_key_info()].
#'
#' @details Provisions a Ubuntu 24.04-x64 droplet with the following customizations:
#'  - A recent version of R installed
#'  - Common server dependencies installed
#'  - Directory structure at `/var/server-apps` for deployed applications
#'  - The `nginx` web server installed to route web traffic from port 80 (HTTP)
#'  - `ufw` installed as a firewall to restrict access on the server. By default it only
#'    allows incoming traffic on port 22 (SSH) and port 80 (HTTP).
#'  - A 4GB swap file is created to ensure that machines with little RAM (the default) are
#'    able to get through the necessary R package compilations.
#'
#' @note Please see \url{https://github.com/sckott/analogsea/issues/205} in case
#'   of an error by default `do_provision` and an error of
#'   `"Error: Size is not available in this region."`.
#'
#' @return The DigitalOcean droplet
#' @export
#' @examples \dontrun{
#'   auth <- analogsea::do_oauth()
#'
#'   analogsea::droplets()
#'   droplet <- do_provision(region = "sfo3")
#'   analogsea::droplets()
#'
#'   # Deploy a _server.yml application
#'   do_deploy_server(
#'     droplet,
#'     "myapp",
#'     "local/path/to/app/",
#'     port=8000,
#'     forward=TRUE
#'   )
#'   if (interactive()) {
#'     utils::browseURL(do_ip(droplet, "/myapp"))
#'   }
#'
#'   analogsea::droplet_delete(droplet)
#' }
do_provision <- function(
  droplet,
  ...,
  keyfile = do_keyfile()
) {
  if (missing(droplet) || is.null(droplet)) {
    # No droplet provided; create a new server
    message("THIS ACTION COSTS YOU MONEY!")
    message(
      "Provisioning a new server for which you will get a bill from DigitalOcean."
    )

    create_args <- list(...)
    create_args$tags <- c(create_args$tags, "buoyant", "server-yml")
    create_args$image <- "ubuntu-24-04-x64"

    # Check if local has ssh keys configured or keyfile provided
    if (!length(do_keyfile()) && is.null(keyfile)) {
      stop(
        "No local ssh key found with `ssh::ssh_key_info()` and `keyfile` argument not provided."
      )
    }

    # Check if DO has ssh keys configured
    if (!length(analogsea::keys())) {
      stop(
        "Please add an ssh key to your Digital Ocean account before using this method. See `analogsea::key_create` method."
      )
    }

    droplet <- do.call(analogsea::droplet_create, create_args)
    Sys.sleep(3)

    # Refresh the droplet; sometimes the original one doesn't yet have a network interface.
    droplet <- with_retries(analogsea::droplet(id = droplet$id))
  }

  # Provision
  lines <- with_retries(droplet_capture(
    droplet,
    'swapon | grep "/swapfile" | wc -l',
    keyfile = keyfile
  ))
  if (lines != "1") {
    analogsea::ubuntu_add_swap(droplet)
  }

  do_install_server_deps(droplet, keyfile = keyfile)

  invisible(droplet)
}

#' Install server dependencies on a droplet
#'
#' Installs R and common dependencies needed for running _server.yml applications.
#' This is called automatically by [do_provision()] but can be called separately
#' if needed.
#'
#' @inheritParams do_provision
#'
#' @return Invisibly returns NULL. Called for side effects.
#' @export
#' @examples
#' \dontrun{
#'   # Reinstall or update server dependencies on an existing droplet
#'   droplet <- analogsea::droplet(123456)
#'   do_install_server_deps(droplet)
#' }
do_install_server_deps = function(droplet, keyfile = do_keyfile()) {
  analogsea::droplet_ssh(
    droplet,
    "sudo echo 'DEBIAN_FRONTEND=noninteractive' >> /etc/environment",
    paste(
      "echo 'options(Ncpus=2, repos=c(\"CRAN\" = \"https://packagemanager.posit.co/cran/__linux__/noble/latest\"))' >> .Rprofile"
    ),
    "curl -O https://cdn.rstudio.com/r/ubuntu-2404/pkgs/r-%s.%s_1_amd64.deb" |>
      sprintf(R.version[["major"]], R.version[["minor"]]),
    keyfile = keyfile
  )
  with_retries(
    analogsea::droplet_ssh(
      droplet,
      "sudo apt-get update -y",
      "sudo apt-get install -y ./r-%s.%s_1_amd64.deb" |>
        sprintf(R.version[["major"]], R.version[["minor"]]),
      keyfile = keyfile
    )
  )
  analogsea::droplet_ssh(
    droplet,
    "sudo ln -s -f /opt/R/%s.%s/bin/R /usr/local/bin/R" |>
      sprintf(R.version[["major"]], R.version[["minor"]]),
    "sudo ln -s -f /opt/R/%s.%s/bin/Rscript /usr/local/bin/Rscript" |>
      sprintf(R.version[["major"]], R.version[["minor"]]),
    keyfile = keyfile
  )
  install_common_deps(droplet, keyfile = keyfile)
  install_server_structure(droplet, keyfile = keyfile)
  install_nginx(droplet, keyfile = keyfile)
  install_firewall(droplet, keyfile = keyfile)
}

install_common_deps <- function(droplet, ...) {
  # Install common system libraries needed by R packages
  with_retries(
    analogsea::ubuntu_apt_get_install(
      droplet,
      "libssl-dev",
      "make",
      "libcurl4-openssl-dev",
      # All other system packages will be installed by `{pak}`
      ...
    )
  )

  # Install pak binary
  analogsea::droplet_ssh(
    droplet,
    "R --quiet -e 'install.packages(\"pak\", repos = sprintf(\"https://r-lib.github.io/p/pak/stable/%s/%s/%s\", .Platform$pkgType, R.Version()$os, R.Version()$arch))'",
    ...
  )
}

#' Captures the output from running some command via SSH
#' @noRd
droplet_capture <- function(droplet, command, ...) {
  tf <- tempdir()
  rand_name <- paste(
    sample(c(letters, LETTERS), size = 10, replace = TRUE),
    collapse = ""
  )
  tff <- file.path(tf, rand_name)
  on.exit({
    if (file.exists(tff)) {
      file.remove(tff)
    }
  })
  analogsea::droplet_ssh(droplet, paste0(command, " > /tmp/", rand_name), ...)
  analogsea::droplet_download(droplet, paste0("/tmp/", rand_name), tf, ...)
  analogsea::droplet_ssh(droplet, paste0("rm /tmp/", rand_name), ...)
  lin <- readLines(tff)
  lin
}

install_server_structure <- function(droplet, ...) {
  # Create directory structure for server applications
  analogsea::droplet_ssh(droplet, "mkdir -p /var/server-apps", ...)
}

install_firewall <- function(droplet, ...) {
  analogsea::droplet_ssh(droplet, "ufw allow http", ...)
  analogsea::droplet_ssh(droplet, "ufw allow ssh", ...)
  analogsea::droplet_ssh(droplet, "ufw -f enable", ...)
}

install_nginx <- function(droplet, ...) {
  with_retries(analogsea::ubuntu_apt_get_install(droplet, "nginx", ...))
  analogsea::droplet_ssh(droplet, "rm -f /etc/nginx/sites-enabled/default", ...) # Disable the default site
  analogsea::droplet_ssh(droplet, "mkdir -p /var/certbot", ...)
  analogsea::droplet_ssh(
    droplet,
    "mkdir -p /etc/nginx/sites-available/server-apps/",
    ...
  )

  # Generate nginx root configuration
  nginx_root_conf <- "# Server application configuration

server {
  listen 80 default_server;
  listen [::]:80 default_server;

  server_name _;

  include /etc/nginx/sites-available/server-apps/*.conf;

  location /.well-known/ {
    root /var/certbot/;
  }
}
"

  tmp_nginx_root <- withr::local_tempfile(fileext = ".conf")
  writeLines(nginx_root_conf, tmp_nginx_root)

  analogsea::droplet_upload(
    droplet,
    local = tmp_nginx_root,
    remote = "/etc/nginx/sites-available/server-apps-root",
    ...
  )
  analogsea::droplet_ssh(
    droplet,
    "ln -sf /etc/nginx/sites-available/server-apps-root /etc/nginx/sites-enabled/",
    ...
  )
  analogsea::droplet_ssh(droplet, "systemctl reload nginx", ...)
}

#' Add HTTPS to a buoyant Droplet
#'
#' Adds TLS/SSL (HTTPS) to a droplet created using [do_provision()].
#'
#' In order to get a TLS/SSL certificate, you need to point a domain name to the
#' IP address associated with your droplet. If you don't already have a domain
#' name, you can register one on [Google Domains](https://domains.google),
#' [Namecheap](https://www.namecheap.com), or [Amazon Route53](https://aws.amazon.com/route53/).
#' When sourcing a domain name, check if your registrar allows you to manage your own DNS
#' records. If not, consider a service like [CloudFlare](https://www.cloudflare.com) to manage
#' your DNS. DigitalOcean also offers DNS management.
#'
#' @param droplet The droplet on which to act. It's expected that this droplet
#'   was provisioned using [do_provision()].  See [analogsea::droplet()] to
#'   obtain a reference to a running droplet.
#' @param domain The domain name associated with this instance. Used to obtain a
#'   TLS/SSL certificate.
#' @param email Your email address; given to letsencrypt for "urgent renewal and
#'   security notices".
#' @param terms_of_service Set to `TRUE` to agree to the letsencrypt subscriber
#'   agreement. At the time of writing, the current version is available
#'   [here](https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf).
#'   Must be set to true to obtain a certificate through letsencrypt.
#' @param force If `FALSE`, will error if the given domain name does not appear
#'   to be registered for this droplet according to DigitalOcean's Metadata service.
#'   If `TRUE`, will ignore any discrepancy and attempt to register anyway.
#' @param ... additional arguments to pass to [analogsea::droplet_ssh()], such as
#'   `keyfile`.
#'
#' @return The DigitalOcean droplet
#' @export
#' @examples
#' \dontrun{
#'   droplet <- analogsea::droplet(123456)
#'
#'   # Add HTTPS support with Let's Encrypt
#'   do_configure_https(
#'     droplet,
#'     domain = "myapp.example.com",
#'     email = "admin@example.com",
#'     terms_of_service = TRUE
#'   )
#' }
do_configure_https <- function(
  droplet,
  domain,
  email,
  terms_of_service = FALSE,
  force = FALSE,
  ...
) {
  if (!force) {
    ip <- analogsea::droplet_ip(droplet)

    # Try to lookup the ip from the domain name to double-check before proceeding.
    # Unfortunately, the `nsl` command is not installed, so we need to query the droplet
    # from the droplet to get a real-time response.
    metadata <- droplet_capture(
      droplet,
      "curl http://169.254.169.254/metadata/v1.json",
      ...
    )

    parsed <- jsonlite::parse_json(metadata, simplifyVector = TRUE)
    floating <- unlist(lapply(parsed$floating_ip, function(ipv) {
      ipv$ip_address
    }))
    ephemeral <- unlist(parsed$interfaces$public)["ipv4.ip_address"]

    if (ip %in% ephemeral) {
      warning(
        "You should consider using a Floating IP address on your droplet for DNS. Currently ",
        "you're using the ephemeral IP address of your droplet for DNS which is dangerous; ",
        "as soon as you terminate your droplet your DNS records will be pointing to an IP ",
        "address you no longer control. A floating IP will give you the opportunity to ",
        "create a new droplet and reassign the floating IP used with DNS later."
      )
    } else if (!ip %in% floating) {
      print(list(
        ip = ip,
        floating_ips = unname(floating),
        ephemeral_ips = unname(ephemeral)
      ))
      stop(
        "It doesn't appear that the domain name '",
        domain,
        "' is pointed to an IP address associated with this droplet. ",
        "This could be due to a DNS misconfiguration or because the changes just haven't propagated through the Internet yet. ",
        "If you believe this is an error, you can override this check by setting force=TRUE."
      )
    }
    message(
      "Confirmed that '",
      domain,
      "' references one of the available IP addresses."
    )
  }

  if (missing(domain)) {
    stop(
      "You must provide a valid domain name which points to this server in order to get an SSL certificate."
    )
  }
  if (missing(email)) {
    stop(
      "You must provide an email to letsencrypt -- the provider of your SSL certificate -- for 'urgent renewal and security notices'."
    )
  }
  if (!terms_of_service) {
    stop(
      "You must agree to the letsencrypt terms of service before running this function"
    )
  }

  # Trim off any protocol prefix if one exists
  domain <- sub("^https?://", "", domain)
  # Trim off any trailing slash if one exists.
  domain <- sub("/$", "", domain)

  # Prepare the nginx SSL configuration
  nginx_ssl_conf <- sprintf(
    "server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name %s;
  return 301 https://$server_name$request_uri;
}

server {
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name %s;

  ssl_certificate /etc/letsencrypt/live/%s/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/%s/privkey.pem;

  include /etc/nginx/sites-available/server-apps/*.conf;

  location /.well-known/ {
    root /var/certbot/;
  }
}
",
    domain,
    domain,
    domain,
    domain
  )

  conffile <- withr::local_tempfile(fileext = ".conf")
  writeLines(nginx_ssl_conf, conffile)

  analogsea::droplet_ssh(droplet, "snap install core")
  analogsea::droplet_ssh(droplet, "snap refresh core")
  analogsea::droplet_ssh(droplet, "snap install --classic certbot")
  analogsea::droplet_ssh(droplet, "ln -s /snap/bin/certbot /usr/bin/certbot")
  analogsea::droplet_ssh(droplet, "ufw allow https", ...)
  analogsea::droplet_ssh(
    droplet,
    sprintf(
      paste0(
        "certbot certonly --webroot -w ",
        "/var/certbot/ -n -d %s --email %s ",
        "--agree-tos --renew-hook ",
        "'/bin/systemctl reload nginx'"
      ),
      domain,
      email
    ),
    ...
  )
  analogsea::droplet_upload(
    droplet,
    conffile,
    "/etc/nginx/sites-available/server-apps-root",
    ...
  )
  analogsea::droplet_ssh(droplet, "systemctl reload nginx", ...)

  invisible(droplet)
}

#' Deploy or Update a _server.yml Application
#'
#' Deploys a _server.yml-based application from your local machine to make it
#' available on the remote server.
#'
#' @param droplet The droplet on which to act. It's expected that this droplet
#'   was provisioned using [do_provision()].  See [analogsea::droplet()] to
#'   obtain a reference to a running droplet.
#' @param path The remote path/name of the application
#' @param local_path The local directory path containing the `_server.yml` file. The entire directory will be deployed.
#' @param port The internal port on which this service should run. This will not
#'   be visible to visitors, but must be unique and point to a port that is available
#'   on your server. If unsure, try a number around `8000`.
#' @param forward If `TRUE`, will setup requests targeting the root URL on the
#'   server to point to this application. See the [do_forward()] function for
#'   more details.
#' @param overwrite if an application is already running for this `path` name,
#'   and `overwrite = TRUE`, then `do_remove_server` will be run.
#' @param ... additional arguments to pass to [analogsea::droplet_ssh()] or
#'   [analogsea::droplet_upload()].
#'   Cannot contain `remote`, `local`, `keyfile` as named arguments.
#' @param keyfile Path to private key for authentication. By default, uses the
#'   key for "digitalocean.com" from [ssh::ssh_key_info()].
#' @param r_packages A character vector of R packages to install via `{pak}` on the server. When `NULL` (default), all dependencies found via `{renv}` will be installed.
#'
#' @return The DigitalOcean droplet
#' @export
do_deploy_server <- function(
  droplet,
  path,
  local_path,
  port,
  forward = FALSE,
  overwrite = FALSE,
  ...,
  keyfile = do_keyfile(),
  r_packages = NULL
) {
  # Trim off any leading slashes
  path <- sub("^/+", "", path)
  # Trim off any trailing slashes if any exist.
  path <- sub("/+$", "", path)

  if (grepl("/", path)) {
    stop(
      "Can't deploy to nested paths. '",
      path,
      "' should not have a / in it."
    )
  }
  if (grepl(" ", path)) {
    stop(
      "Can't deploy to paths with whitespace. '",
      path,
      "' should not have a whitespace in it."
    )
  }

  # Validate the _server.yml file exists
  local_path <- normalizePath(local_path)
  server_yml_path <- file.path(local_path, "_server.yml")
  if (!file.exists(server_yml_path)) {
    stop(
      "Your server directory must contain a `_server.yml` file. ",
      server_yml_path,
      " does not exist"
    )
  }

  # Validate the _server.yml file locally
  message("Validating _server.yml file...")
  validate_server_yml(local_path, check_engine = FALSE, verbose = FALSE)
  config <- read_server_yml(local_path)
  engine <- config$engine

  message("Deploying _server.yml application with engine: ", engine)

  # Find R dependencies
  if (is.null(r_packages)) {
    r_packages = unique(
      renv::dependencies(local_path, quiet = TRUE)$Package
    )
  }
  if (!is.character(r_packages)) {
    stop(
      "`r_packages=` must be a character vector of package names. `character(0)` is OK."
    )
  }

  ### UPLOAD the Application ###
  remote_tmp <- paste0(
    "/tmp/",
    paste0(sample(LETTERS, 10, replace = TRUE), collapse = "")
  )
  dir_name <- gsub("^\\.?$", "*", basename(local_path))
  dir_name <- gsub(" ", "\\\\ ", dir_name)

  server_path = paste0("/var/server-apps/", path)

  # Check if path already exists
  if (overwrite) {
    output = try(
      {
        do_remove_server(
          droplet,
          path = path,
          delete = TRUE,
          ...,
          keyfile = keyfile
        )
      },
      silent = TRUE
    )
    if (inherits(output, "try-error")) {
      msg = paste0("Tried to remove ", path, " application but had issues")
      warning(msg)
    }
  }

  cmd = paste0(
    "if [ -d ",
    server_path,
    " ]; then echo 'TRUE'; else echo 'FALSE'; fi"
  )
  check_path = droplet_capture(droplet, cmd, keyfile = keyfile)
  path_exists = grepl("TRUE", check_path, ignore.case = TRUE)

  if (path_exists) {
    stop(
      "An application already exists at path='",
      path,
      "'. ",
      "Please remove it using do_remove_server() or use overwrite = TRUE"
    )
  }

  analogsea::droplet_ssh(
    droplet,
    paste0("mkdir -p ", remote_tmp),
    keyfile = keyfile
  )
  analogsea::droplet_upload(
    droplet,
    local = local_path,
    remote = remote_tmp,
    keyfile = keyfile
  )
  analogsea::droplet_ssh(
    droplet,
    paste0("mv ", remote_tmp, "/", dir_name, " ", server_path),
    keyfile = keyfile
  )
  analogsea::droplet_ssh(
    droplet,
    paste0("rm -rf ", remote_tmp),
    keyfile = keyfile
  )

  ### Install the engine if not present ###
  install_r_pkgs(droplet, c("any::yaml", engine, r_packages), keyfile = keyfile)

  ### Create systemd service ###
  message("Creating systemd service...")
  service_name <- paste0("server-", path)

  # Create R script for the service to execute
  r_script <- sprintf(
    "engine <- yaml::read_yaml('_server.yml')$engine; launch_server <- get('launch_server', envir = asNamespace(engine), mode = 'function'); launch_server('_server.yml', host = '127.0.0.1', port = %d)",
    port
  )

  service_file <- sprintf(
    "[Unit]
Description=Server application: %s
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=%s
ExecStart=/usr/local/bin/Rscript -e \"%s\"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
",
    path,
    server_path,
    r_script
  )

  # Write service file to temp location
  tmp_service <- withr::local_tempfile()
  writeLines(service_file, tmp_service)

  analogsea::droplet_upload(
    droplet,
    local = tmp_service,
    remote = paste0("/etc/systemd/system/", service_name, ".service"),
    keyfile = keyfile
  )
  analogsea::droplet_ssh(
    droplet,
    "systemctl daemon-reload",
    keyfile = keyfile
  )
  analogsea::droplet_ssh(
    droplet,
    paste0("systemctl enable ", service_name),
    keyfile = keyfile
  )
  analogsea::droplet_ssh(
    droplet,
    paste0("systemctl restart ", service_name),
    keyfile = keyfile
  )

  ### Create nginx configuration ###
  message("Configuring nginx...")
  nginx_conf <- sprintf(
    "location /%s/ {
    proxy_pass http://127.0.0.1:%d/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection \"upgrade\";
    proxy_read_timeout 600s;
}
",
    path,
    port
  )

  tmp_nginx <- withr::local_tempfile(fileext = ".conf")
  writeLines(nginx_conf, tmp_nginx)

  analogsea::droplet_upload(
    droplet,
    local = tmp_nginx,
    remote = paste0("/etc/nginx/sites-available/server-apps/", path, ".conf"),
    keyfile = keyfile
  )

  # Include all server-apps configs in main nginx config if not already included
  analogsea::droplet_ssh(
    droplet,
    paste0(
      "grep -q 'include /etc/nginx/sites-available/server-apps/\\*.conf;' ",
      "/etc/nginx/sites-available/server-apps-root || ",
      "sed -i '/server {/a \\    include /etc/nginx/sites-available/server-apps/*.conf;' ",
      "/etc/nginx/sites-available/server-apps-root"
    ),
    keyfile = keyfile
  )

  analogsea::droplet_ssh(droplet, "systemctl reload nginx", keyfile = keyfile)

  if (forward) {
    do_forward(droplet, path, keyfile = keyfile)
  }

  message("Application deployed successfully!")
  message("Access it at: ", do_ip(droplet, paste0("/", path)))

  invisible(droplet)
}

#' Forward root requests to an application
#'
#' Configures nginx to forward requests from the root path (/) to a specific application.
#'
#' @param droplet The droplet on which to act.
#' @param path The application path to forward root requests to.
#' @param ... additional arguments to pass to [analogsea::droplet_ssh()].
#'
#' @return The DigitalOcean droplet
#' @export
#' @examples
#' \dontrun{
#'   droplet <- analogsea::droplet(123456)
#'
#'   # Forward root URL to an application
#'   do_forward(droplet, "myapp")
#'
#'   # Now visiting http://your-ip/ will redirect to http://your-ip/myapp
#' }
do_forward <- function(droplet, path, ...) {
  path <- sub("^/+", "", path)
  path <- sub("/+$", "", path)

  nginx_conf <- sprintf(
    "location = / {
  return 307 /%s;
}",
    path
  )

  forwardfile <- withr::local_tempfile(fileext = ".conf")
  writeLines(nginx_conf, forwardfile)

  analogsea::droplet_upload(
    droplet,
    forwardfile,
    "/etc/nginx/sites-available/server-apps/_forward.conf",
    ...
  )

  analogsea::droplet_ssh(droplet, "systemctl reload nginx", ...)

  invisible(droplet)
}

#' Remove a deployed application
#'
#' Removes a deployed _server.yml application from the server.
#'
#' @param droplet The droplet on which to act.
#' @param path The path/name of the application to remove.
#' @param delete If `TRUE`, also deletes the application files. If `FALSE`,
#'   just stops and disables the service.
#' @param ... additional arguments to pass to [analogsea::droplet_ssh()].
#'
#' @return The DigitalOcean droplet
#' @export
#' @examples
#' \dontrun{
#'   droplet <- analogsea::droplet(123456)
#'
#'   # Stop the service but keep files
#'   do_remove_server(droplet, "myapp", delete = FALSE)
#'
#'   # Remove the service and delete all files
#'   do_remove_server(droplet, "myapp", delete = TRUE)
#' }
do_remove_server <- function(droplet, path, delete = FALSE, ...) {
  path <- sub("^/+", "", path)
  path <- sub("/+$", "", path)

  if (grepl("/", path)) {
    stop(
      "Can't deploy to nested paths. '",
      path,
      "' should not have a / in it."
    )
  }

  # Given that we're about to `rm -rf`, let's just be safe...
  if (grepl("\\.\\.", path)) {
    stop("Paths don't allow '..'s.")
  }
  if (nchar(path) == 0) {
    stop("Path cannot be empty.")
  }
  try_ssh = function(...) {
    try(analogsea::droplet_ssh(...), silent = TRUE)
  }

  service_name <- paste0("server-", path)

  message("Stopping service '", service_name, "'...")
  try_ssh(droplet, paste0("systemctl stop ", service_name), ...)
  try_ssh(
    droplet,
    paste0("systemctl disable ", service_name),
    ...
  )
  try_ssh(
    droplet,
    paste0("rm /etc/systemd/system/", service_name, ".service"),
    ...
  )
  try_ssh(droplet, "systemctl daemon-reload", ...)

  message("Removing nginx configuration...")
  try_ssh(
    droplet,
    paste0("rm -f /etc/nginx/sites-available/server-apps/", path, ".conf"),
    ...
  )
  try_ssh(droplet, "systemctl reload nginx", ...)

  if (delete) {
    message("Deleting application files...")
    server_path <- paste0("/var/server-apps/", path)
    try_ssh(droplet, paste0("rm -rf ", server_path), ...)
  }

  message("Application '", path, "' removed successfully!")
  invisible(droplet)
}

#' Remove root forwarding
#'
#' Removes any root path forwarding configuration.
#'
#' @param droplet The droplet on which to act.
#' @param ... additional arguments to pass to [analogsea::droplet_ssh()].
#'
#' @return This function currently stops with an error. Not yet implemented.
#' @export
#' @examples
#' \dontrun{
#'   droplet <- analogsea::droplet(123456)
#'
#'   # This function is not yet implemented
#'   do_remove_forward(droplet)
#' }
do_remove_forward <- function(droplet, ...) {
  stop(
    "Remove forward functionality is not yet implemented.\n",
    "Please manually edit nginx configuration at /etc/nginx/sites-available/server-apps-root",
    call. = FALSE
  )
}

#' Get the URL to a deployed application
#'
#' Returns the URL to access a deployed application or the droplet's IP address.
#'
#' @param droplet The droplet on which to act.
#' @param path Optional path to append to the IP address. If not provided, just
#'   returns the IP address.
#'
#' @return A character string with the URL or IP address.
#' @export
do_ip = function(droplet, path) {
  ip <- analogsea::droplet_ip(droplet)

  if (!missing(path) && !is.null(path)) {
    path <- sub("^/+", "", path)
    paste0("http://", ip, "/", path)
  } else {
    ip
  }
}

#' Get the default DigitalOcean SSH keyfile path
#'
#' Returns the path to the SSH private key for "digitalocean.com" from
#' [ssh::ssh_key_info()]. This is used as the default keyfile for all
#' buoyant functions that interact with DigitalOcean droplets.
#'
#' @return A character string with the path to the SSH private key, or NULL
#'   if no key is found.
#' @export
#' @examples
#' \dontrun{
#'   # Get the default keyfile path
#'   do_keyfile()
#' }
do_keyfile <- function() {
  ssh::ssh_key_info("digitalocean.com")$key
}
