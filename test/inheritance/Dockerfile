FROM usabillabv/php:7.2-cli-alpine3.7 as compile-php-extension

RUN set -x \
    && apk add --no-cache gnupg postgresql-client postgresql-dev \
    && docker-php-source-tarball download \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-source-tarball clean \
    && apk del gnupg postgresql-dev

FROM usabillabv/php:7.2-cli-alpine3.7 as compile-php-pecl-extension

RUN set -x \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && pecl clear-cache \
    && docker-php-source-tarball clean \
    && apk del .phpize-deps 
