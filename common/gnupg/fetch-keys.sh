#!/bin/sh

for key in $GPG_KEYS; do
    unset found;

    for server in $GPG_SERVERS; do
        echo "Fetching GPG key $key from $server";
        gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$key" && found=yes && break;
    done;

    test -z "$found" && echo >&2 "error: failed to fetch GPG key $key" && exit 1;
done;

echo "Keys imported!"
