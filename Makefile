build: clean-tags build-cli build-fpm build-http
push: push-cli build-fpm push-http
ci-push-cli: ci-docker-login push-cli
ci-push-fpm: ci-docker-login push-fpm
ci-push-http: ci-docker-login push-http
qa: build test lint

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

.PHONY: *

BUILDINGIMAGE=*

# Docker PHP images build matrix ./build-php.sh (cli/fpm) (PHP version) (Alpine version)
build-cli: BUILDINGIMAGE=cli
build-cli: clean-tags
	./build-php.sh cli 7.2 3.7
	./build-php.sh cli 7.2 3.8
	# ./build-php.sh cli 7.3-rc 3.8

build-fpm: BUILDINGIMAGE=fpm
build-fpm: clean-tags
	./build-php.sh fpm 7.2 3.7
	./build-php.sh fpm 7.2 3.8
	# ./build-php.sh fpm 7.3-rc 3.8

# Docker HTTP images build matrix ./build-nginx.sh (nginx version) (extra tag)
build-http: BUILDINGIMAGE=http
build-http: clean-tags
	./build-nginx.sh 1.15 nginx # nginx v1.5 is currently carrying the `nginx` tag but so far we only tested 1.14
	./build-nginx.sh 1.14

.NOTPARALLEL: clean-tags
clean-tags: 
	rm ${current_dir}/tmp/build-${BUILDINGIMAGE}.tags || true

# Docker images push
push-cli: build-cli
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %
push-fpm: build-fpm
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %
push-http: build-http
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %

# CI dependencies
ci-docker-login:
	docker login --username $$DOCKER_USER --password $$DOCKER_PASSWORD

