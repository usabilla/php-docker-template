#!/bin/bash

set -xeEuo pipefail

IMAGE="http"

VERSION_NGINX=$1

IMAGE_EXTRA_TAG=${2:-}

# I could create a placeholder like php:x.y-image-alpinex.y in the Dockerfile itself,
# but I think it wouldn't be a good experience if you try to build the image yourself
# thus that's the way I opted to have dynamic base images
IMAGE_ORIGINAL_TAG="nginx:1.[0-9][0-9]?-alpine"

IMAGE_TAG="nginx:${VERSION_NGINX}-alpine"
USABILLA_TAG_PREFIX="usabillabv/php"
USABILLA_TAG="${USABILLA_TAG_PREFIX}:nginx${VERSION_NGINX}"
USABILLA_TAG_DEV="${USABILLA_TAG}-dev"
USABILLA_EXTRA_TAG="${USABILLA_TAG_PREFIX}:${IMAGE_EXTRA_TAG}"
USABILLA_EXTRA_TAG_DEV="${USABILLA_EXTRA_TAG}-dev"

TAG_FILE="./tmp/build-${IMAGE}.tags"

sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "Dockerfile-${IMAGE}" | docker build -t "${USABILLA_TAG}" --target="${IMAGE}" -f - . \
    && echo "${USABILLA_TAG}" >> "${TAG_FILE}"

sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "Dockerfile-${IMAGE}" | docker build -t "${USABILLA_TAG_DEV}" --target="${IMAGE}-dev" -f - . \
    && echo "$USABILLA_TAG_DEV" >> "${TAG_FILE}"

if [[ -n ${IMAGE_EXTRA_TAG} ]]; then
    docker tag "${USABILLA_TAG}" "${USABILLA_EXTRA_TAG}" && echo "${USABILLA_EXTRA_TAG}" >> "${TAG_FILE}"
    docker tag "${USABILLA_TAG_DEV}" "${USABILLA_EXTRA_TAG_DEV}" && echo "${USABILLA_EXTRA_TAG_DEV}" >> "${TAG_FILE}"
fi
