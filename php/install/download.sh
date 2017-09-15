#!/bin/sh

set -xe

cd /usr/src

wget -O php.tar.xz "$PHP_URL"
wget -O php.tar.xz.asc "$PHP_ASC_URL"

echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -;

gpg --batch --verify php.tar.xz.asc php.tar.xz
