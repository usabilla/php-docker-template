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
if [[ ! -v DOCKER_BUILD_PLATFORM ]]; then
   declare -r DOCKER_BUILD_FLAGS=""
   declare -r USABILLA_TAG_SUFFIX=""
else
   declare -r DOCKER_BUILD_FLAGS="--platform=${DOCKER_BUILD_PLATFORM}"
   # shellcheck disable=SC2155
   declare -r USABILLA_TAG_SUFFIX="-${DOCKER_BUILD_PLATFORM//\//-}"
fi
declare -r USABILLA_TAG="${USABILLA_TAG_PREFIX}:${IMAGE}${USABILLA_TAG_SUFFIX}"

declare -r TAG_FILE="./tmp/build-${IMAGE}${USABILLA_TAG_SUFFIX}.tags"

# shellcheck disable=SC2086
sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "Dockerfile-${DOCKER_FILE}" | docker build --pull -t "${USABILLA_TAG}" \
    --build-arg=NGINX_VHOST_TEMPLATE=prometheus-exporter-file --target="http" ${DOCKER_BUILD_FLAGS} -f - . \
    && echo "${USABILLA_TAG}" >> "${TAG_FILE}"

for USABILLA_TAG_EXTRA in "${@:2}"
do
    docker tag "${USABILLA_TAG}" "${USABILLA_TAG_PREFIX}:${USABILLA_TAG_EXTRA}${USABILLA_TAG_SUFFIX}" \
    && echo "${USABILLA_TAG_PREFIX}:${USABILLA_TAG_EXTRA}${USABILLA_TAG_SUFFIX}" >> "${TAG_FILE}"
done
