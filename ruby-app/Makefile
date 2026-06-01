# Makefile
DEV_COMPOSE := compose.dev.yml

.PHONY: run install lint build up down help css \
	dev dev-build dev-down dev-logs

run:
	ruby app.rb

install:
	bundle install

css:
	bundle exec tailwindcss -i public/input.css -o public/output.css --watch

lint:
	bundle exec rubocop

build:
	docker build -t whoknows .

up:
	docker compose up --build

down:
	docker compose down

# --- Local dev (Docker Compose, multi-arch: works on x86 + ARM) ---

dev-build:
	docker compose -f $(DEV_COMPOSE) build

dev:
	docker compose -f $(DEV_COMPOSE) up -d --build

dev-down:
	docker compose -f $(DEV_COMPOSE) down

dev-logs:
	docker compose -f $(DEV_COMPOSE) logs -f

help:
	@echo "make run        - Run app locally (Ruby + SQLite)"
	@echo "make css        - Run Tailwind CSS watcher in background"
	@echo "make install    - Bundle install dependencies"
	@echo "make lint       - Run RuboCop linter"
	@echo "make build      - Build production Docker image"
	@echo "make up         - Build and run production container on :8080"
	@echo "make down       - Stop the production container"
	@echo "make dev        - Start dev stack (web + css watcher + db) on :8080"
	@echo "make dev-build  - Build dev images only"
	@echo "make dev-down   - Stop the dev stack"
	@echo "make dev-logs   - Tail dev stack logs"