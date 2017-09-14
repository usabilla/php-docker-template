#!/bin/sh

set -xe

cd /usr/src

wget -O php.tar.xz "$PHP_URL"

echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -;

wget -O php.tar.xz.asc "$PHP_ASC_URL"
export GNUPGHOME="$(mktemp -d)"

for key in $PHP_GPG_KEYS; do
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key";
done;

gpg --batch --verify php.tar.xz.asc php.tar.xz
rm -rf "$GNUPGHOME"
