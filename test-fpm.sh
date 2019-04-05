#!/bin/bash
#
# A simple script to start a Docker container
# and run Testinfra in it
# Original script: https://gist.github.com/renatomefi/bbf44d4e8a2614b1390416c6189fbb8e
# Author: @renatomefi https://github.com/renatomefi
#

set -eEuo pipefail

# The first parameter is a Docker tag or image id
declare -r DOCKER_TAG="$1"

declare TEST_SUITE

if [[ $DOCKER_TAG == *"-dev" ]]; then
    TEST_SUITE="php or php_fpm or php_dev"
else
    TEST_SUITE="php or php_fpm or php_no_dev and not php_dev"
fi

printf "Starting a container for '%s'\\n" "$DOCKER_TAG"

DOCKER_CONTAINER=$(docker run --rm -t -d "$DOCKER_TAG")
readonly DOCKER_CONTAINER

# Let's register a trap function, if our tests fail, finish or the script gets
# interrupted, we'll still be able to remove the running container
function tearDown {
    docker rm -f "$DOCKER_CONTAINER" &>/dev/null &
}
trap tearDown EXIT TERM ERR

# Finally, run the tests!
docker run --rm -t \
    -v "$(pwd)/test:/tests" \
    -v "$(pwd)/tmp/test-results:/results" \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    renatomefi/docker-testinfra:2 \
    -m "$TEST_SUITE" --junitxml="/results/php-fpm-$DOCKER_TAG.xml" \
    --verbose --hosts="docker://$DOCKER_CONTAINER"
