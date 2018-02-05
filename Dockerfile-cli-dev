FROM usabillabv/php-base:cli

RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del .phpize-deps

COPY common/php/conf/debug.ini /usr/local/etc/php/conf.d/zzz_debug.ini
