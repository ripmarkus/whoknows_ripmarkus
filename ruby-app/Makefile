# Makefile
.PHONY: run install lint build up down help

run:
	ruby app.rb

install:
	bundle install

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
	@echo "make install  - Bundle install dependencies"
	@echo "make lint     - Run RuboCop linter"
	@echo "make build    - Build Docker image"
	@echo "make up       - Build and run Docker container on :8080"
	@echo "make down     - Stop the Docker container"