# Advanced Usage

Once you’ve deployed your first application with `buoyant`, you’ll want
to know how to manage it, update it, and use more advanced features.
This guide covers everything from updating your deployed applications to
running multiple apps on a single server, configuring HTTPS, and
understanding how buoyant works under the hood.

## Prerequisites

This guide assumes you’ve already:

- Completed the [Getting
  Started](https://posit-dev.github.io/buoyant/articles/buoyant.md)
  tutorial
- Successfully deployed at least one application
- Have a running DigitalOcean droplet with buoyant

If you haven’t done these yet, start with the [Getting
Started](https://posit-dev.github.io/buoyant/articles/buoyant.md) guide
first.

## What You’ll Learn

In this guide, you’ll learn how to:

- **Manage deployments**: Update, redeploy, and remove applications
- **Work with existing droplets**: Reference and reuse droplets without
  recreating them
- **Customize your setup**: Configure droplet sizes, regions, and
  resource specifications
- **Deploy multiple apps**: Run several applications on a single server
- **Enable HTTPS**: Add SSL certificates with Let’s Encrypt
- **Monitor applications**: Check logs and service status
- **Install dependencies**: Add system libraries and R packages to your
  server

## Managing Your Deployment

### Update Your Application

Make changes locally, then redeploy:

``` r

do_deploy_server(
  droplet = droplet,
  path = "api",
  local_path = "my-first-api",
  port = 8000,
  overwrite = TRUE # Replace existing deployment
)
```

### Deploy Multiple Applications

``` r

# Deploy a second application on the same server
do_deploy_server(
  droplet = droplet,
  path = "v2",
  local_path = "my-second-api",
  port = 8001 # Different port!
)

# Access at:
# http://<ip>/api   (first app)
# http://<ip>/v2    (second app)
```

### Remove an Application

``` r

# Stop and remove
do_remove_server(droplet, path = "api", delete = TRUE)
```

### Delete the Server

When you’re completely done:

``` r

library(analogsea)
droplet_delete(droplet)
```

**Warning**: This permanently deletes your server and all data!

## Working with Existing Droplets

You don’t need to create a new droplet every time. You can reference
existing droplets:

``` r

# Get a reference to an existing droplet by ID
droplet <- droplet(id = 12345678)

# Or by name
library(purrr)
droplet <- droplets() %>%
  keep(~ .x$name == "my-server") %>%
  pluck(1)

# Deploy to it
do_deploy_server(droplet, "newapp", "path/to/app", port = 8002)
```

## Custom DigitalOcean Configuration

You can customize the droplet specifications:

``` r

# Provision with specific size, region, and name
droplet <- do_provision(
  size = "s-1vcpu-1gb", # 1 CPU, 1GB RAM
  region = "sfo3", # San Francisco data center
  name = "my-production-api" # Custom name
)
```

Common droplet sizes: - `s-1vcpu-512mb` - \$5/month (basic) -
`s-1vcpu-1gb` - \$10/month

See [DigitalOcean pricing](https://www.digitalocean.com/pricing) for
current rates.

## Root Path Forwarding

By default, applications are accessible at `http://ip/path`. You can
forward the root path to an application:

``` r

# Make an app accessible at the root
do_forward(droplet, "myapp")

# Now accessible at: http://ip/ instead of http://ip/myapp

# Remove forwarding
do_remove_forward(droplet)
```

## Installing Server Dependencies

If your application needs system libraries or R packages:

``` r

# Install system packages
droplet_ssh(droplet, "sudo apt-get install -y libgdal-dev")

# Install R packages on the server
do_install_server_deps(droplet, packages = c("sf", "terra"))
```

## Monitoring Your Application

### Check Service Status

SSH into your droplet to check logs:

``` r

droplet_ssh(droplet, "journalctl -u server-api -f")
```

Or use analogsea’s convenience functions:

``` r

# Check if service is running
droplet_ssh(droplet, "systemctl status server-api")
```

### View Application Logs

``` r

# View recent logs
droplet_ssh(droplet, "journalctl -u server-myapp -n 50")

# Follow logs in real-time
droplet_ssh(droplet, "journalctl -u server-myapp -f")
```

### Check Resource Usage

``` r

# Check memory and CPU usage
droplet_ssh(droplet, "htop")

# Check disk usage
droplet_ssh(droplet, "df -h")
```

## Optional: Add HTTPS

If you have a domain name:

``` r

# Point your domain to the droplet IP
ip <- do_ip(droplet)
print(ip)

# After DNS is configured (wait for propagation):
do_configure_https(
  droplet = droplet,
  domain = "api.yourdomain.com",
  email = "you@example.com",
  terms_of_service = TRUE # Agree to Let's Encrypt TOS
)
```

Now your API is available at `https://api.yourdomain.com/api`

## How It Works

Understanding how `buoyant` works under the hood can help with
troubleshooting:

### Provisioning (`do_provision()`)

- Creates a DigitalOcean droplet with Ubuntu
- Installs R, nginx, and required system libraries
- Configures firewall (ports 22, 80, 443)
- Sets up directory structure (`/var/server-apps/`)

### Deployment (`do_deploy_server()`)

- Uploads application files to `/var/server-apps/<path>/`

- Installs the engine package if not present

- Creates a systemd service file at
  `/etc/systemd/system/server-<path>.service`

- The service runs:

  ``` r
  Rscript -e "
    engine <- yaml::read_yaml('_server.yml')$engine
    launch_server <- get('launch_server', envir = asNamespace(engine))
    launch_server('_server.yml', host = '127.0.0.1', port = <port>)
  "
  ```

- Creates nginx configuration at
  `/etc/nginx/sites-available/server-<path>`

- Enables and starts the service

### HTTPS (`do_configure_https()`)

- Installs certbot
- Obtains SSL certificate from Let’s Encrypt
- Updates nginx configuration for HTTPS
- Sets up automatic certificate renewal

## Best Practices

1.  **Version Control**: Keep your applications in git repositories
2.  **Environment Variables**: Use environment variables for secrets
    (not in `_server.yml`)
3.  **Testing**: Test locally before deploying
4.  **Monitoring**: Set up monitoring and alerts for production
    applications
5.  **Backups**: Regularly backup your application code and data
6.  **Security**: Use HTTPS in production, keep packages updated
7.  **Resource Sizing**: Start small, scale up as needed
8.  **Cost Management**: Remember to delete droplets when not in use
    ([`droplet_delete()`](https://pacha.dev/analogsea/reference/droplet_delete.html))

## Comparison with plumberDeploy

If you’re familiar with
[plumberDeploy](https://github.com/meztez/plumberDeploy), here’s how
`buoyant` differs:

| Feature           | buoyant                  | plumberDeploy            |
|-------------------|--------------------------|--------------------------|
| Framework Support | Any `_server.yml` engine | plumber only             |
| Configuration     | `_server.yml` standard   | `plumber.R` files        |
| Deployment Target | DigitalOcean             | DigitalOcean, AWS, Azure |
| HTTPS Support     | Yes (Let’s Encrypt)      | Yes (Let’s Encrypt)      |
| Multiple Apps     | Yes                      | Yes                      |

`buoyant` is more focused but framework-agnostic, while `plumberDeploy`
supports multiple cloud providers but is specific to plumber.

## Next Steps

- See the [Troubleshooting
  vignette](https://posit-dev.github.io/buoyant/articles/troubleshooting.md)
  for common issues
- Explore different
  [engines](https://plumber2.posit.co/articles/server_yml.html)
- Set up CI/CD for automated deployments
- Learn about DigitalOcean features like load balancers and databases
