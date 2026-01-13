# Troubleshooting

When deploying applications with `buoyant`, you may occasionally
encounter issues. This guide helps you diagnose and fix the most common
problems, from connection failures to application crashes.

## How to Use This Guide

This troubleshooting guide is organized by problem type. To find help:

1.  **Identify your problem**: Look at the section headings to find what
    matches your issue
2.  **Check the symptoms**: Each section describes what you’ll see when
    the problem occurs
3.  **Follow the solutions**: Try the diagnostic commands and fixes
    provided
4.  **Use the checklist**: If you’re not sure where to start, see the
    [Debugging Checklist](#debugging-checklist)

## Quick Diagnostic Tips

Before diving into specific problems:

- **Check the logs first**: Most issues show up in the logs

``` r

analogsea::droplet_ssh(droplet, "journalctl -u server-myapp -n 50")
```

- **Verify the service is running**:

``` r

analogsea::droplet_ssh(droplet, "systemctl status server-myapp")
```

- **Test locally before deploying**: Use
  [`validate_server_yml()`](https://posit-dev.github.io/buoyant/reference/validate_server_yml.md)
  to catch configuration errors early

## Common Issues at a Glance

| Problem | Likely Cause | Quick Fix |
|----|----|----|
| Can’t access application | Service not running | Restart service or check logs |
| “Connection refused” | Port/firewall issue | Check port with `netstat -tlnp` |
| Application crashes | Missing dependencies | Install packages with [`do_install_server_deps()`](https://posit-dev.github.io/buoyant/reference/do_install_server_deps.md) |
| Nginx errors | Configuration syntax | Run `nginx -t` to test config |
| SSL certificate fails | DNS not propagated | Wait 5-60 minutes for DNS |

## Connection Issues

### Droplet Connection Refused

If you can’t connect to your droplet:

``` r

# Refresh droplet information
droplet <- analogsea::droplet(droplet$id)

# Check IP is accessible
ip <- analogsea::droplet_ip(droplet)
system(paste("ping -c 3", ip))
```

**Common causes:** - Droplet is still provisioning (wait a few
minutes) - Firewall blocking connections - SSH keys not configured
properly

### Can’t Access Application

If your application URL isn’t responding:

``` r

# Check if the service is running
analogsea::droplet_ssh(droplet, "systemctl status server-myapp")

# Check if nginx is running
analogsea::droplet_ssh(droplet, "systemctl status nginx")
```

## Application Not Starting

### Check Service Logs

The most useful troubleshooting tool is the service logs:

``` r

# View recent logs
analogsea::droplet_ssh(droplet, "journalctl -u server-myapp -n 50")

# Follow logs in real-time
analogsea::droplet_ssh(droplet, "journalctl -u server-myapp -f")
```

### Common Issues

**Missing Dependencies**

If you see errors about missing packages, add
`if (FALSE) library(missingpkg)` lines to your app code or install them
manually:

``` r

# Install missing packages via pak
analogsea::droplet_ssh(
  droplet,
  "R -e 'pak::pkg_install(c(\"missingpkg1\", \"missingpkg2\"))'"
)

# Or install system dependencies directly if needed
analogsea::ubuntu_apt_get_install(droplet, "libcurl4-openssl-dev")
analogsea::ubuntu_apt_get_install(droplet, c("libxml2-dev", "libssl-dev"))
```

[pak](https://pak.r-lib.org/) installs packages AND their system
dependencies automatically.

**Port Conflicts**

If the port is already in use:

``` r

# Check what's using the port
analogsea::droplet_ssh(droplet, "netstat -tlnp | grep 8000")

# Use a different port for your application
do_deploy_server(droplet, "myapp", "path/to/app", port = 8001)
```

**Invalid `_server.yml`**

Validate your configuration locally before deploying:

``` r

# Check your _server.yml syntax
validate_server_yml("my-app", check_engine = TRUE, verbose = TRUE)

# Read and inspect configuration
config <- read_server_yml("my-app")
str(config)
```

### Check Service Exists

Verify the systemd service was created:

``` r

# List all server services
analogsea::droplet_ssh(droplet, "systemctl list-units | grep server-")

# Check specific service status
analogsea::droplet_ssh(droplet, "systemctl status server-myapp")
```

### Restart Service

Sometimes a restart helps:

``` r

# Restart the service
analogsea::droplet_ssh(droplet, "sudo systemctl restart server-myapp")

# Check status after restart
analogsea::droplet_ssh(droplet, "systemctl status server-myapp")
```

## Nginx Issues

### Test Nginx Configuration

``` r

# Test nginx configuration for syntax errors
analogsea::droplet_ssh(droplet, "nginx -t")

# If errors, view the configuration
analogsea::droplet_ssh(droplet, "cat /etc/nginx/sites-available/server-myapp")
```

### Check Nginx Logs

``` r

# Check nginx error log
analogsea::droplet_ssh(droplet, "tail -f /var/log/nginx/error.log")

# Check nginx access log
analogsea::droplet_ssh(droplet, "tail -f /var/log/nginx/access.log")
```

### Restart Nginx

``` r

# Restart nginx
analogsea::droplet_ssh(droplet, "sudo systemctl restart nginx")

# Check status
analogsea::droplet_ssh(droplet, "systemctl status nginx")
```

## Validation Errors

### Local Validation

Before deploying, validate your application:

``` r

# Basic validation
validate_server_yml("my-app")

# Validate and check that engine is installed locally
validate_server_yml("my-app", check_engine = TRUE)

# Verbose output for debugging
validate_server_yml("my-app", check_engine = TRUE, verbose = TRUE)
```

### Common Validation Issues

**Missing Engine Field**

Your `_server.yml` must have an `engine` field:

``` yaml
engine: plumber2
```

## Deployment Failures

### Upload Failures

If files fail to upload:

``` r

# Check SSH connection
analogsea::droplet_ssh(droplet, "echo 'Connection works'")

# Check available disk space
analogsea::droplet_ssh(droplet, "df -h")

# Try deploying again with overwrite
do_deploy_server(droplet, "myapp", "path/to/app", port = 8000, overwrite = TRUE)
```

### Package Installation Failures

If the engine package fails to install:

``` r

# Check R is installed
analogsea::droplet_ssh(droplet, "R --version")

# Try installing the package manually
analogsea::install_r_package(droplet, "plumber2")
```

## HTTPS/SSL Issues

### Certificate Not Issued

If Let’s Encrypt certificate fails:

``` r

# Check certbot logs
analogsea::droplet_ssh(droplet, "cat /var/log/letsencrypt/letsencrypt.log")

# Verify DNS is configured correctly
# (must wait for DNS propagation, usually 5-60 minutes)
system(paste("nslookup", "api.yourdomain.com"))
```

**Common causes:** - DNS not propagated yet (wait and try again) -
Domain doesn’t point to droplet IP - Rate limit hit (Let’s Encrypt has
rate limits)

### Certificate Renewal Issues

``` r

# Test certificate renewal
analogsea::droplet_ssh(droplet, "sudo certbot renew --dry-run")

# Check renewal timer status
analogsea::droplet_ssh(droplet, "systemctl status certbot.timer")
```

## Performance Issues

### High Memory Usage

``` r

# Check memory usage
analogsea::droplet_ssh(droplet, "free -h")

# Check which processes are using memory
analogsea::droplet_ssh(droplet, "ps aux --sort=-%mem | head -n 10")

# Consider upgrading to a larger droplet
droplet <- do_provision(size = "s-2vcpu-4gb")
```

### Slow Response Times

``` r

# Check CPU usage
analogsea::droplet_ssh(droplet, "top -bn1 | head -20")

# Check if application is under heavy load
analogsea::droplet_ssh(
  droplet,
  "journalctl -u server-myapp -n 100 | grep -i error"
)
```

## Debugging Checklist

When something goes wrong, work through this checklist:

1.  **Can you connect to the droplet?**

    ``` r

    analogsea::droplet_ssh(droplet, "echo 'Connected'")
    ```

2.  **Is the service running?**

    ``` r

    analogsea::droplet_ssh(droplet, "systemctl status server-myapp")
    ```

3.  **What do the logs say?**

    ``` r

    analogsea::droplet_ssh(droplet, "journalctl -u server-myapp -n 50")
    ```

4.  **Is the port listening?**

    ``` r

    analogsea::droplet_ssh(droplet, "netstat -tlnp | grep 8000")
    ```

5.  **Is nginx working?**

    ``` r

    analogsea::droplet_ssh(droplet, "nginx -t && systemctl status nginx")
    ```

6.  **Is the `_server.yml` valid?**

    ``` r

    validate_server_yml("my-app", check_engine = TRUE, verbose = TRUE)
    ```

## Getting More Help

If you’re still stuck:

1.  **Check the logs** - They usually contain the answer
2.  **Search existing issues** -
    <https://github.com/posit-dev/buoyant/issues>
3.  **File a new issue** with:
    - Your `_server.yml` file
    - Service logs (`journalctl -u server-myapp -n 100`)
    - Steps to reproduce the problem
4.  **Review the documentation**:
    - [Getting
      Started](https://posit-dev.github.io/buoyant/articles/buoyant.md)
    - [Advanced
      Usage](https://posit-dev.github.io/buoyant/articles/advanced-usage.md)
    - [Function
      Reference](https://posit-dev.github.io/buoyant/reference/)

## Related Resources

- [DigitalOcean
  troubleshooting](https://docs.digitalocean.com/products/droplets/)
- [analogsea documentation](https://github.com/pachadotdev/analogsea)
- [systemd
  documentation](https://www.freedesktop.org/software/systemd/man/)
- [nginx documentation](https://nginx.org/en/docs/)
