#!/bin/sh

set -xe

cd /usr/local/etc

if [ -d php-fpm.d ]; then
    # for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
    sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null;
    cp php-fpm.d/www.conf.default php-fpm.d/www.conf;
else
    # PHP 5.x doesn't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
    mkdir php-fpm.d;
    cp php-fpm.conf.default php-fpm.d/www.conf;
    { \
        echo '[global]'; \
        echo 'include=etc/php-fpm.d/*.conf'; \
    } | tee php-fpm.conf;
fi
