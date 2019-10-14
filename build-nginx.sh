#!/bin/bash

set -eEuo pipefail

export DOCKER_BUILDKIT=1

declare -r IMAGE="http"

declare -r VERSION_NGINX=$1

# I could create a placeholder like nginx:x.y-alpine in the Dockerfile itself,
# but I think it wouldn't be a good experience if you try to build the image yourself
# thus that's the way I opted to have dynamic base images
declare -r IMAGE_ORIGINAL_TAG="nginx:1.[0-9][0-9]?-alpine"

declare -r IMAGE_TAG="nginx:${VERSION_NGINX}-alpine"
declare -r USABILLA_TAG_PREFIX="usabillabv/php"
declare -r USABILLA_TAG="${USABILLA_TAG_PREFIX}:nginx${VERSION_NGINX}"
declare -r USABILLA_TAG_DEV="${USABILLA_TAG}-dev"

TAG_FILE="./tmp/build-${IMAGE}.tags"

sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "Dockerfile-${IMAGE}" | docker build --pull -t "${USABILLA_TAG}" \
    --build-arg=NGINX_VHOST_TEMPLATE=php-fpm --target="${IMAGE}" -f - . \
    && echo "${USABILLA_TAG}" >> "${TAG_FILE}"

sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "Dockerfile-${IMAGE}" | docker build --pull -t "${USABILLA_TAG_DEV}" \
    --build-arg=NGINX_VHOST_TEMPLATE=php-fpm --target="${IMAGE}-dev" -f - . \
    && echo "$USABILLA_TAG_DEV" >> "${TAG_FILE}"

for IMAGE_EXTRA_TAG in "${@:2}"
do
    declare NEW_TAG="${USABILLA_TAG_PREFIX}:${IMAGE_EXTRA_TAG}"
    docker tag "${USABILLA_TAG}" "${NEW_TAG}" && echo "${NEW_TAG}" >> "${TAG_FILE}"
    docker tag "${USABILLA_TAG_DEV}" "${NEW_TAG}-dev" && echo "${NEW_TAG}-dev" >> "${TAG_FILE}"
done
