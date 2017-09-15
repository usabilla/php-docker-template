#!/bin/sh

set -xe

cd /usr/src

curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz
curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc

gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz
