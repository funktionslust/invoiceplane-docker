# InvoicePlane Docker

[![Docker Version](https://img.shields.io/docker/v/funktionslust/invoiceplane/latest?label=docker)](https://hub.docker.com/r/funktionslust/invoiceplane)
[![Docker Pulls](https://img.shields.io/docker/pulls/funktionslust/invoiceplane)](https://hub.docker.com/r/funktionslust/invoiceplace)

Production-ready Docker image for [InvoicePlane v1](https://github.com/InvoicePlane/InvoicePlane) - the self-hosted open source invoicing application.

> **Note:** This image is for InvoicePlane v1.x. [InvoicePlane v2](https://github.com/InvoicePlane/InvoicePlane-v2) is a separate project currently in development.

**GitHub:** [https://github.com/funktionslust/invoiceplane-docker](https://github.com/funktionslust/invoiceplane-docker)

**Docker Hub:** [https://hub.docker.com/r/funktionslust/invoiceplane](https://hub.docker.com/r/funktionslust/invoiceplane)

**Tags:**
- `latest`, `production` - Latest stable InvoicePlane release
- `1.x.x` - Specific version tags (all stable releases >= 1.6.0)
- `development`, `dev` - Development branch (bleeding edge)

## Features

- All stable InvoicePlane releases (automatically built)
- E-Invoice Support
- Multi-architecture: linux/amd64 and linux/arm64
- PHP 8.1 with Apache on Debian Bookworm
- Security headers, OPcache enabled, optimized settings
- Reverse Proxy / Trusted Proxies Support
- Config ipconfig.php via environment vars

## Quick Start

```bash
docker compose up -d
```

Access at `http://localhost:8080` and follow the setup wizard.

**Note:** After completing the setup wizard, the container will automatically set `DISABLE_SETUP=true` for security on the next restart. To manually re-enable the setup wizard, set the environment variable `DISABLE_SETUP=false`.

## Environment Variables

### Docker/PHP Settings

- `TZ` - Timezone (default: UTC)
- `PHP_MEMORY_LIMIT` - PHP memory limit (default: 256M)
- `PHP_UPLOAD_MAX_FILESIZE` - Maximum upload file size (default: 32M)
- `PHP_POST_MAX_SIZE` - Maximum POST size (default: 32M)
- `PHP_MAX_EXECUTION_TIME` - Maximum execution time in seconds (default: 300)

### Proxy Settings

- `PROXY_NETWORKS` - Space-separated list of trusted proxy IP ranges for X-Forwarded-For headers (default: "172.16.0.0/12 10.0.0.0/8")

### InvoicePlane Configuration

**Application Settings:**
- `IP_URL` - Base URL for InvoicePlane (e.g. https://invoice.example.com) - **Required for correct redirects**
- `ENABLE_DEBUG` - Enable debug logging (default: false)
- `CI_ENV` - Environment mode: production or development (default: production)
- `DISABLE_SETUP` - Disable setup wizard for security (default: false)
- `REMOVE_INDEXPHP` - Remove index.php from URLs (default: false)

**Database Settings:**
Note: These are only set if empty. Setup wizard values take precedence.
- `IP_DB_HOSTNAME` - Database hostname
- `IP_DB_USERNAME` - Database username
- `IP_DB_PASSWORD` - Database password
- `IP_DB_DATABASE` - Database name
- `IP_DB_PORT` - Database port (default: 3306)
- `IP_DB_PREFIX` - Table prefix (default: ip_)

**Security Settings:**
- `X_FRAME_OPTIONS` - X-Frame-Options header (default: SAMEORIGIN)
- `ENABLE_X_CONTENT_TYPE_OPTIONS` - Enable X-Content-Type-Options header (default: true)
- `SESS_REGENERATE_DESTROY` - Destroy session on regeneration (default: false)

**Session Settings:**
- `SESS_EXPIRATION` - Session expiration in seconds, 0 for browser close (default: 864000 = 10 days)
- `SESS_MATCH_IP` - Match session to IP address (default: true)

**Calculation Settings:**
- `LEGACY_CALCULATION` - Use legacy tax calculation (default: true)

**Feature Flags:**
- `ENABLE_INVOICE_DELETION` - Allow invoice deletion (default: false)
- `DISABLE_READ_ONLY` - Disable read-only mode for invoices (default: false)

**Swiss Medical (Sumex):**
- `SUMEX_SETTINGS` - Enable Sumex customizations (default: false)
- `SUMEX_URL` - Sumex PDF generation URL

**E-Invoice Templates:**
- `INSTALL_EINVOICE_TEMPLATES` - Comma-separated list of e-invoice templates to install on startup (e.g., "zugferd-extended,facturx")

## Volumes

- `/var/www/html/uploads` - Uploaded files
- `/var/www/html/application/logs` - Application logs

## E-Invoice Support

InvoicePlane supports various e-invoice formats (ZUGFeRD, Factur-X, UBL, FacturaE, FatturaPA). Templates can be installed automatically via environment variable or manually using the included script.

### Automatic Installation (via Environment Variable)

Set the `INSTALL_EINVOICE_TEMPLATES` environment variable with a comma-separated list of template IDs:

```yaml
environment:
  - INSTALL_EINVOICE_TEMPLATES=zugferd-extended,facturx
```

**Available template IDs:**
- `facturxv10`, `facturx` - Factur-X v1.0 (French)
- `ublexamv20`, `ubl` - UBL 2.0 Example (Universal)
- `zugferdv23extended`, `zugferd-extended` - ZUGFeRD v2.3 Extended (German)
- `zugferdv23basic`, `zugferd-basic` - ZUGFeRD v2.3 Basic (German)
- `zugferdv23basicwl`, `zugferd-basicwl` - ZUGFeRD v2.3 Basic WL (German)
- `facturaev32`, `facturae` - FacturaE v3.2 (Spanish)
- `fatturapav12`, `fatturapa` - FatturaPA v1.2 (Italian)

### Manual Installation (Interactive Script)

You can also install templates manually using the interactive script:

```bash
docker exec -it invoiceplane download-einvoice-templates.sh
```

For more information: [InvoicePlane E-Invoices Repository](https://github.com/InvoicePlane/InvoicePlane-e-invoices)

## Docker Image Tags

Available on both [Docker Hub](https://hub.docker.com/r/funktionslust/invoiceplane/tags) and [GitHub Container Registry](https://github.com/funktionslust/invoiceplane-docker/pkgs/container/invoiceplane-docker):

<!-- TAGS_START -->
| Tag | Description |
|-----|-------------|
| `latest`, `production` | Latest stable release |
| `1.7.0`, `1.6.4`, `1.6.3`, `1.6.2`, `1.6.1`, `1.6.0` | Specific versions |
| `development`, `dev` | Development branch |
<!-- TAGS_END -->

```bash
docker pull funktionslust/invoiceplane:latest
docker pull funktionslust/invoiceplane:development
```

## License

This Docker image configuration (Dockerfile, scripts, etc.) is licensed under the MIT License - see [LICENSE](LICENSE)

InvoicePlane itself is licensed under its own MIT-style license - see [InvoicePlane LICENSE](https://github.com/InvoicePlane/InvoicePlane/blob/development/LICENSE.txt)

---

**Maintained by:** Funktionslust GmbH - Wolfgang Stark ([info@funktionslust.digital](mailto:info@funktionslust.digital))
