# Add HTTPS to a buoyant Droplet

Adds TLS/SSL (HTTPS) to a droplet created using
[`do_provision()`](https://posit-dev.github.io/buoyant/reference/do_provision.md).

## Usage

``` r
do_configure_https(
  droplet,
  domain,
  email,
  terms_of_service = FALSE,
  force = FALSE,
  ...
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

- domain:

  The domain name associated with this instance. Used to obtain a
  TLS/SSL certificate.

- email:

  Your email address; given to letsencrypt for "urgent renewal and
  security notices".

- terms_of_service:

  Set to `TRUE` to agree to the letsencrypt subscriber agreement. At the
  time of writing, the current version is available
  [here](https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf).
  Must be set to true to obtain a certificate through letsencrypt.

- force:

  If `FALSE`, will error if the given domain name does not appear to be
  registered for this droplet according to DigitalOcean's Metadata
  service. If `TRUE`, will ignore any discrepancy and attempt to
  register anyway.

- ...:

  additional arguments to pass to
  [`analogsea::droplet_ssh()`](https://pacha.dev/analogsea/reference/droplet_ssh.html),
  such as `keyfile`.

## Value

The DigitalOcean droplet

## Details

In order to get a TLS/SSL certificate, you need to point a domain name
to the IP address associated with your droplet. If you don't already
have a domain name, you can register one on [Google
Domains](https://domains.google) or [Amazon
Route53](https://aws.amazon.com/route53/).

When sourcing a domain name, check if your registrar allows you to
manage your own DNS records. If not, consider a service like
[CloudFlare](https://www.cloudflare.com) to manage your DNS.
DigitalOcean also offers DNS management.

## Examples

``` r
if (FALSE) { # \dontrun{
  droplet <- analogsea::droplet(123456)

  # Add HTTPS support with Let's Encrypt
  do_configure_https(
    droplet,
    domain = "myapp.example.com",
    email = "admin@example.com",
    terms_of_service = TRUE
  )
} # }
```
