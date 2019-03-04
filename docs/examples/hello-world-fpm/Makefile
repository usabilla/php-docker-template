SHELL=bash

# set all to phony
.PHONY: *

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

PROJECT_NAME=usabilla-docker-hello-world-fpm
IMAGE_TAG=usabillabv/php

DOCKER_RUN=docker run --rm -t \
	-v "${current_dir}:/opt/project" -v "${HOME}/.config/composer:/.config/composer" \
	-e COMPOSER_HOME=/.config/composer \
	--workdir=/opt/project \
	"${IMAGE_TAG}:${PROJECT_NAME}-dev"

all: install check up ## Runs everything

install: docker-build install-composer

check: docker-lint

export DOCKER_BUILDKIT=1
docker-build:
	docker build -t "${IMAGE_TAG}:${PROJECT_NAME}-dev" --target=dev -f Dockerfile .

docker-check: # If the docker image isn't built, do it
ifeq ($(shell docker images --filter=reference="${IMAGE_TAG}:${PROJECT_NAME}-dev" --format={{.ID}}),)
	$(MAKE) docker-build
endif

docker-lint: # Lints Dockerfile with Hadolint
	docker run --rm -t -v $(current_dir):/p --workdir=/p hadolint/hadolint:latest-debian hadolint ./Dockerfile

PORT?=8080
up: docker-check # Runs Nginx and FPM containers while sharing the socket among them
	@docker run --name "${PROJECT_NAME}-fpm" --rm -d -m 256M -v $(current_dir):/opt/project:rw "${IMAGE_TAG}:${PROJECT_NAME}-dev"
	@docker run --name "${PROJECT_NAME}-nginx" --rm -d -m 64M -p ${PORT}:80 --volumes-from="${PROJECT_NAME}-fpm" "${IMAGE_TAG}:nginx" || ($(MAKE) down && exit 1)
	@echo -e "\033[0;32m [RUNNING] \033[0m       \033[0;33m http://localhost:${PORT}/\033[0m"

down: # Stop the containers
	@docker stop -t 2 "${PROJECT_NAME}-nginx" || true
	@docker stop -t 5 "${PROJECT_NAME}-fpm" || true
	@echo -e "\033[0;32m [STOPPED] \033[0m\033[0m" $<

install-composer: docker-check ## Install dependencies with composer
	$(DOCKER_RUN) composer install -n -o $(FLAGS)
