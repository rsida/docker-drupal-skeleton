.DEFAULT_GOAL := help
include .env
export

DOCKER_EXEC = docker compose exec php
COMPOSER    = $(DOCKER_EXEC) composer
DRUSH       = $(DOCKER_EXEC) php vendor/bin/drush

##@ Setup

install: _env up _wait-db _drupal-install ## First-time setup: create a new Drupal project
reset: ## Wipe Drupal source and database, then reinstall from scratch
	@echo "Clearing Drupal source files..."
	docker compose up -d php 2>/dev/null || true
	docker compose exec php sh -c "find /var/www/html -mindepth 1 \
		-not -path '/var/www/html/.git*' \
		-not -name 'compose.yaml' \
		-not -name 'Makefile' \
		-not -name 'README.md' \
		-not -name '.env' \
		-not -name '.env.example' \
		-not -name '.gitignore' \
		-not -path '/var/www/html/docker*' \
		-delete" 2>/dev/null || true
	@echo "Stopping containers and wiping volumes..."
	docker compose down -v
	find . -mindepth 1 \
		-not -path './.git*' \
		-not -name '.env' \
		-not -name '.env.example' \
		-not -name '.gitignore' \
		-not -name 'Makefile' \
		-not -name 'README.md' \
		-not -name 'compose.yaml' \
		-not -path './docker*' \
		-delete 2>/dev/null || true
	@echo "Starting fresh install..."
	$(MAKE) install
setup: _env up _wait-db _drupal-setup ## Setup an existing project after cloning

##@ Development

up: _env ## Start containers
	docker compose up -d --build

down: ## Stop containers
	docker compose down

restart: down up ## Restart containers

shell: ## Open bash in php container
	docker compose exec php bash

drush: ## Run a Drush command: make drush CMD="status"
	$(DRUSH) $(CMD)

composer: ## Run a Composer command: make composer CMD="require drupal/admin_toolbar"
	$(COMPOSER) $(CMD)

logs: ## Follow container logs
	docker compose logs -f

ps: ## Show running containers
	docker compose ps

##@ Database

db-migrate: ## Run pending database updates
	$(DRUSH) updatedb -y

db-import: ## Import a SQL dump: make db-import FILE=dump.sql
	docker compose exec -T mariadb mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < $(FILE)

db-export: ## Export the database
	$(DRUSH) sql-dump --result-file=../dump.sql --gzip
	@echo "Database exported to dump.sql.gz"

##@ Cache & maintenance

cc: ## Clear Drupal cache
	$(DRUSH) cache:rebuild

cron: ## Run cron
	$(DRUSH) cron

##@ Utilities

check-network: ## Verify Traefik network exists
	@docker network inspect $(TRAEFIK_NETWORK) > /dev/null 2>&1 \
		&& echo "Network '$(TRAEFIK_NETWORK)' exists." \
		|| echo "ERROR: Network '$(TRAEFIK_NETWORK)' does not exist. Create it with: docker network create $(TRAEFIK_NETWORK)"

hosts: ## Print /etc/hosts entry to add
	@echo "Add the following line to your /etc/hosts file:"
	@echo "127.0.0.1  $(APP_DOMAIN) mail.$(APP_DOMAIN)"

help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# ─── Internal helpers ──────────────────────────────────────────────────────────

_env:
	@test -f .env || (cp .env.example .env && echo ".env created from .env.example")

_wait-db:
	@echo "Waiting for MariaDB..."
	@until docker compose exec mariadb mariadb-admin ping -h localhost --silent; do sleep 1; done
	@echo "MariaDB is ready."

_drupal-install:
	@if [ ! -f composer.json ]; then \
		docker run --rm \
			-v $(CURDIR):/project \
			-e COMPOSER_ALLOW_SUPERUSER=1 \
			composer:2 sh -c "composer create-project drupal/recommended-project:^10 /tmp/drupal --no-interaction --ignore-platform-reqs && cp -rn /tmp/drupal/. /project/"; \
	fi
	@if [ ! -f vendor/bin/drush ]; then \
		docker run --rm \
			-v $(CURDIR):/project \
			-w /project \
			-e COMPOSER_ALLOW_SUPERUSER=1 \
			composer:2 composer require drush/drush --ignore-platform-reqs; \
	fi
	docker compose exec php sh -c "mkdir -p web/sites/default/files/translations && chmod -R 777 web/sites/default/files"
	$(DRUSH) site:install standard \
		--db-url=mysql://$(DB_USER):$(DB_PASSWORD)@mariadb:3306/$(DB_NAME) \
		--site-name="$(APP_NAME)" \
		--account-pass=admin \
		--locale=en \
		-y
	$(DRUSH) config-set locale.settings translation.import_enabled 0 -y
	$(DRUSH) config-set locale.settings translation.check_disabled_modules 0 -y
	$(DRUSH) cache:rebuild
	@echo ""
	@echo "Drupal installed."
	@echo "  Site  : https://$(APP_DOMAIN)"
	@echo "  Admin : https://$(APP_DOMAIN)/user/login"
	@echo "  Login : admin / admin"
	@echo "  Mail  : https://mail.$(APP_DOMAIN)"

_drupal-setup:
	$(COMPOSER) install
	$(DRUSH) updatedb -y
	$(DRUSH) cache:rebuild
