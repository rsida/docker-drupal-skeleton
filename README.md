# Docker Drupal Skeleton

A ready-to-use Docker development environment for **Drupal 10** applications.

Stack: PHP 8.3-FPM · Nginx (Alpine) · MariaDB 11 · Mailpit · Traefik (external)

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Docker + Docker Compose v2 | `docker compose version` |
| [local-network-multisite](../local-network-multisite) | Traefik reverse proxy must be running |
| [mkcert](https://github.com/FiloSottile/mkcert) | For trusted local HTTPS certificates |

---

## Getting started

### New project (first time)

```bash
# 1. Clone this skeleton
git clone <this-repo> my-app
cd my-app

# 2. Copy and review environment variables
cp .env.example .env
$EDITOR .env

# 3. Add the local domain to /etc/hosts
make hosts
# → 127.0.0.1  drupal.local mail.drupal.local

# 4. Verify Traefik network
make check-network

# 5. Install Drupal and start containers
make install
```

After `make install` your site is available at `https://drupal.local`.

- **Admin:** `https://drupal.local/user/login`
- **Login / Password:** `admin` / `admin`

### Existing project

```bash
cp .env.example .env
$EDITOR .env
make setup
```

---

## Available commands

| Command | Description |
|---|---|
| `make install` | Create new Drupal project and run site install |
| `make reset` | Wipe everything (files + DB) and reinstall from scratch |
| `make setup` | Set up existing project (composer install + db update) |
| `make up` | Start containers |
| `make down` | Stop and remove containers |
| `make restart` | Restart all containers |
| `make shell` | Bash shell in PHP container |
| `make drush CMD="..."` | Run any Drush command |
| `make composer CMD="..."` | Run any Composer command |
| `make db-migrate` | Run pending database updates (`drush updatedb`) |
| `make db-import FILE=dump.sql` | Import a SQL dump |
| `make db-export` | Export the database to `dump.sql.gz` |
| `make db-shell` | Open MariaDB interactive shell |
| `make cc` | Clear Drupal cache (`drush cache:rebuild`) |
| `make cron` | Run Drupal cron |
| `make logs` | Follow all container logs |
| `make ps` | Show running containers |
| `make check-network` | Verify Traefik network exists |
| `make hosts` | Print the `/etc/hosts` line required |
| `make help` | Display all available targets |

---

## Architecture

### Services

| Service | Image | Purpose |
|---|---|---|
| `nginx` | `nginx:alpine` | Web server, serves Drupal from `web/` and proxies PHP requests |
| `php` | `php:8.3-fpm` (custom) | PHP-FPM with Drupal extensions, Composer, Drush, Xdebug |
| `mariadb` | `mariadb:11` | Relational database |
| `mailer` | `axllent/mailpit` | Local SMTP + web UI for email testing |

### Networks

| Network | Type | Purpose |
|---|---|---|
| `traefik-net` | external (shared) | Traefik routing |
| `internal` | bridge | Inter-service communication |

### Xdebug

Xdebug 3 is pre-installed and configured for step debugging on port **9003**.
Set your IDE (e.g. PhpStorm) to listen on that port with IDE key `PHPSTORM`.

To disable Xdebug in production, override `xdebug.ini` with `xdebug.mode=off`.

---

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `drupal` | Used as Docker container name prefix and Traefik router name |
| `APP_DOMAIN` | `drupal.local` | Primary application domain |
| `APP_ENV` | `development` | Application environment |
| `TRAEFIK_NETWORK` | `traefik-net` | Name of the external Docker network shared with Traefik |
| `DB_ROOT_PASSWORD` | `root` | MariaDB root password |
| `DB_NAME` | `drupal` | Database name |
| `DB_USER` | `drupal` | Database user |
| `DB_PASSWORD` | `drupal` | Database password |

---

## Related projects

- [local-network-multisite](../local-network-multisite) — Traefik + mkcert infrastructure
- [docker-symfony-skeleton](../docker-symfony-skeleton) — Symfony skeleton
- [docker-sylius-skeleton](../docker-sylius-skeleton) — Sylius e-commerce skeleton
- [docker-wordpress-skeleton](../docker-wordpress-skeleton) — WordPress skeleton
- [docker-woocommerce-skeleton](../docker-woocommerce-skeleton) — WooCommerce skeleton
- [docker-cakephp-skeleton](../docker-cakephp-skeleton) — CakePHP skeleton
- [docker-joomla-skeleton](../docker-joomla-skeleton) — Joomla skeleton
- [docker-prestashop-skeleton](../docker-prestashop-skeleton) — PrestaShop skeleton
- [docker-magento-skeleton](../docker-magento-skeleton) — Magento 2 skeleton
- [docker-laravel-skeleton](../docker-laravel-skeleton) — Laravel skeleton
- [docker-shopify-skeleton](../docker-shopify-skeleton) — Shopify skeleton
