#!/bin/sh

set -xe

cd /usr/src

curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz
curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc

export GNUPGHOME="$(mktemp -d)"

for server in $NGINX_GPG_SERVERS; do
    echo "Fetching GPG key $GPG_KEYS from $server";
    gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPG_KEYS" && found=yes && break;
done;

test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPG_KEYS" && exit 1;
gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz

rm -rf "$GNUPGHOME"
