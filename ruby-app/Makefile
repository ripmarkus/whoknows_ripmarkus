# Makefile
.PHONY: run install lint build up down help css

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

up: build
	docker run --rm --name whoknows -p 8080:8080 --env-file .env whoknows

down:
	docker stop whoknows

help:
	@echo "make run      - Run app locally (Ruby + SQLite)"
	@echo "make css      - Run Tailwind CSS watcher in background"
	@echo "make install  - Bundle install dependencies"
	@echo "make lint     - Run RuboCop linter"
	@echo "make build    - Build Docker image"
	@echo "make up       - Build and run Docker container on :8080"
	@echo "make down     - Stop the Docker container"