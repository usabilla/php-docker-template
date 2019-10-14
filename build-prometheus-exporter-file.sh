#!/bin/bash

set -eEuo pipefail

export DOCKER_BUILDKIT=1

declare -r IMAGE="prometheus-exporter-file"

declare -r DOCKER_FILE="http"

declare -r VERSION_NGINX=$1

# I could create a placeholder like nginx:x.y-alpine in the Dockerfile itself,
# but I think it wouldn't be a good experience if you try to build the image yourself
# thus that's the way I opted to have dynamic base images
declare -r IMAGE_ORIGINAL_TAG="nginx:1.[0-9][0-9]?-alpine"

declare -r IMAGE_TAG="nginx:${VERSION_NGINX}-alpine"
declare -r USABILLA_TAG_PREFIX="usabillabv/php"
declare -r USABILLA_TAG="${USABILLA_TAG_PREFIX}:${IMAGE}"

TAG_FILE="./tmp/build-${IMAGE}.tags"

sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "Dockerfile-${DOCKER_FILE}" | docker build --pull -t "${USABILLA_TAG}" \
    --build-arg=NGINX_VHOST_TEMPLATE=prometheus-exporter-file --target="http" -f - . \
    && echo "${USABILLA_TAG}" >> "${TAG_FILE}"

for USABILLA_TAG_EXTRA in "${@:2}"
do
    docker tag "${USABILLA_TAG}" "${USABILLA_TAG_PREFIX}:${USABILLA_TAG_EXTRA}" \
    && echo "${USABILLA_TAG_PREFIX}:${USABILLA_TAG_EXTRA}" >> "${TAG_FILE}"
done
