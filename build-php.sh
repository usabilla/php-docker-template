#!/bin/bash

set -eEuo pipefail

export DOCKER_BUILDKIT=1

declare -r IMAGE=$1

declare -r VERSION_PHP=$2

declare -r VERSION_ALPINE=$3

# I could create a placeholder like php:x.y-image-alpinex.y in the Dockerfile itself,
# but I think it wouldn't be a good experience if you try to build the image yourself
# thus that's the way I opted to have dynamic base images
declare -r IMAGE_ORIGINAL_TAG="7.[0-9]-${IMAGE}-alpine3.[0-9]"

declare -r IMAGE_TAG="${VERSION_PHP}-${IMAGE}-alpine${VERSION_ALPINE}"
if [[ ! -v DOCKER_BUILD_PLATFORM ]]; then
   declare -r DOCKER_BUILD_FLAGS=""
   declare -r USABILLA_TAG_SUFFIX=""
else
   declare -r DOCKER_BUILD_FLAGS="--platform=${DOCKER_BUILD_PLATFORM}"
   # shellcheck disable=SC2155
   declare -r USABILLA_TAG_SUFFIX="-${DOCKER_BUILD_PLATFORM//\//-}"
fi
declare -r USABILLA_TAG_PREFIX="usabillabv/php:${VERSION_PHP}-${IMAGE}-alpine${VERSION_ALPINE}"
declare -r USABILLA_TAG="${USABILLA_TAG_PREFIX}${USABILLA_TAG_SUFFIX}"
declare -r USABILLA_TAG_DEV="${USABILLA_TAG_PREFIX}-dev${USABILLA_TAG_SUFFIX}"

declare -r TAG_FILE="./tmp/build-${IMAGE}${USABILLA_TAG_SUFFIX}.tags"

# shellcheck disable=SC2086
sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "Dockerfile-${IMAGE}" | docker build --pull -t "${USABILLA_TAG}" --target="${IMAGE}" ${DOCKER_BUILD_FLAGS} -f - . \
    && echo "$USABILLA_TAG" >> "$TAG_FILE"

# shellcheck disable=SC2086
sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "Dockerfile-${IMAGE}" | docker build --pull -t "${USABILLA_TAG_DEV}" --target="${IMAGE}-dev" ${DOCKER_BUILD_FLAGS} -f - . \
    && echo "$USABILLA_TAG_DEV" >> "$TAG_FILE"
