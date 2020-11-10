# syntax=docker/dockerfile:1.0.0-experimental

FROM 644152709166.dkr.ecr.eu-west-1.amazonaws.com/usabilla/dev/dockerhub-mirror/usabillabv/php:7.3-fpm-alpine3.9 AS base

FROM 644152709166.dkr.ecr.eu-west-1.amazonaws.com/usabilla/dev/dockerhub-mirror/composer:1 as composer

FROM 644152709166.dkr.ecr.eu-west-1.amazonaws.com/usabilla/dev/dockerhub-mirror/base as source

ENV COMPOSER_HOME=/opt/.composer

RUN apk add --no-cache git

COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /opt/archived

# hadolint ignore=SC2215
RUN --mount=type=bind,source=./,rw \
    mkdir -p /opt/project \
    && git archive --verbose --format tar HEAD | tar -x -C /opt/project

WORKDIR /opt/project

# hadolint ignore=SC2215
RUN --mount=type=secret,id=composer.auth,target=/opt/project/auth.json \
    --mount=type=bind,source=.composer/cache,target=/opt/.composer/cache \
    composer install --no-interaction --no-progress --no-dev --prefer-dist --classmap-authoritative

FROM 644152709166.dkr.ecr.eu-west-1.amazonaws.com/usabilla/dev/dockerhub-mirror/base as prod

WORKDIR /opt/project

COPY --chown=app:app --from=source /opt/project /opt/project

FROM 644152709166.dkr.ecr.eu-west-1.amazonaws.com/usabilla/dev/dockerhub-mirror/base AS dev

COPY --chown=app:app --from=composer /usr/bin/composer /usr/bin/composer

RUN docker-php-dev-mode xdebug \
    && docker-php-dev-mode config

VOLUME [ "/opt/project" ]
