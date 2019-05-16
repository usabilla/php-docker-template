FROM php:7.2-cli-alpine3.7 as cli

# Add usabilla user and group
RUN set -x \
    && addgroup -g 1000 app \
    && adduser -u 1000 -D -G app app

# Install docker help scripts
COPY src/php/utils/docker/ /usr/local/bin/

# Install PHP extensions
RUN set -x \
    && apk add --no-cache wget \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && docker-php-ext-install pcntl opcache \
    && pecl install apcu \
    && pecl clear-cache \
    && docker-php-ext-enable apcu \
    # Removing all PHP leftovers since the helper scripts nor the official image are removing them
    && docker-php-source-tarball clean && rm /usr/local/bin/php-cgi && rm /usr/local/bin/phpdbg && rm -rf /tmp/pear ~/.pearrc \
    && apk del .phpize-deps

# Patch CVE-2018-14618 (curl), CVE-2018-16842 (libxml2), CVE-2019-11068 (libxslt)
RUN apk upgrade --no-cache curl libxml2 libxslt

# Create a symlink to the recommended production configuration
# ref: https://github.com/docker-library/docs/tree/master/php#configuration
RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini

COPY src/gpg /usr/local/etc/gpg
COPY src/php/conf/ /usr/local/etc/php/conf.d/
COPY src/php/cli/conf/*.ini /usr/local/etc/php/conf.d/

# Install shush
COPY src/php/utils/install-shush /usr/local/bin/
RUN install-shush && rm -rf /usr/local/bin/install-shush

# Install composer
COPY src/php/utils/install-composer /usr/local/bin/
RUN install-composer && rm -rf /usr/local/bin/install-composer

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/shush", "exec", "docker-php-entrypoint"]

# Base images don't need healthcheck since they are not running applications
# this can be overriden in the child images
HEALTHCHECK NONE

## CLI-DEV STAGE ##
FROM cli as cli-dev

# Install Xdebug and development specific configuration
RUN docker-php-dev-mode xdebug \
    && docker-php-dev-mode config

# Change entrypoint back to the default because we don't need shush in development
ENTRYPOINT ["docker-php-entrypoint"]
