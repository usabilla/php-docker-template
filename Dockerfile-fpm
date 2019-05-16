FROM php:7.2-fpm-alpine3.7 as fpm

ENV FCGI_CONNECT=/var/run/php-fpm.sock

# Add usabilla user and group
RUN set -x \
    && addgroup -g 1000 app \
    && adduser -u 1000 -D -G app app

# Install docker help scripts
COPY src/php/utils/docker/ /usr/local/bin/
COPY src/php/utils/install-* /usr/local/bin/

# Install PHP extensions
RUN set -x \
    && apk add --no-cache wget \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && docker-php-ext-install opcache \
    && pecl install apcu \
    && pecl clear-cache \
    && docker-php-ext-enable apcu \
    # those deletions happen since the helper scripts nor the official image are removing them
    && docker-php-source-tarball clean && rm /usr/local/bin/phpdbg && rm -rf /tmp/pear ~/.pearrc \
    && apk del .phpize-deps \
    && apk add --no-cache fcgi

# Patch CVE-2018-14618 (curl), CVE-2018-16842 (libxml2), CVE-2019-11068 (libxslt)
RUN apk upgrade --no-cache curl libxml2 libxslt

# Create a symlink to the recommended production configuration
# ref: https://github.com/docker-library/docs/tree/master/php#configuration
RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini

COPY src/gpg /usr/local/etc/gpg
COPY src/php/conf/ /usr/local/etc/php/conf.d/
COPY src/php/fpm/conf/*.conf /usr/local/etc/php-fpm.d/

# Install shush, dumb-init and composer
RUN install-shush && rm -f /usr/local/bin/install-shush \
    && install-dumb-init && rm -f /usr/local/bin/install-dumb-init \
    && install-composer && rm -f /usr/local/bin/install-composer

STOPSIGNAL SIGTERM

ENTRYPOINT [ "docker-php-entrypoint-init" ]
CMD ["--force-stderr"]

# Base images don't need healthcheck since they are not running applications
# this can be overriden in the child images
HEALTHCHECK NONE

VOLUME [ "/var/run" ]

## FPM-DEV STAGE ##
FROM fpm as fpm-dev

# Install Xdebug and development specific configuration
RUN docker-php-dev-mode xdebug \
    && docker-php-dev-mode config
