push: push-cli build-fpm push-http
build: clean-tags build-cli build-fpm build-http
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
build-fpm: clean-tags
	./build-php.sh fpm 7.2 3.7
	./build-php.sh fpm 7.2 3.8
	# ./build-php.sh fpm 7.3-rc 3.8

# Docker HTTP images build matrix ./build-nginx.sh (nginx version) (extra tag)
build-http: BUILDINGIMAGE=http
build-http: clean-tags
	./build-nginx.sh 1.15 nginx # nginx v1.5 is currently carrying the `nginx` tag but so far we only  tested 1.14
	./build-nginx.sh 1.14

clean-tags:
	rm ${current_dir}/tmp/build-${BUILDINGIMAGE}.tags || true

# Docker images push
push-cli: build-cli
	docker push usabillabv/php-base:cli
push-fpm: build-fpm
	docker push usabillabv/php-base:fpm
push-http: build-http
	docker push usabillabv/php-base:http

# CI dependencies
ci-docker-login:
	docker login --username $$DOCKER_USER --password $$DOCKER_PASSWORD

lint:
	docker run -v ${current_dir}:/project:ro --workdir=/project --rm -it hadolint/hadolint:latest-debian hadolint /project/Dockerfile-cli /project/Dockerfile-fpm /project/Dockerfile-http

test:
	docker-compose -p php-docker-template-tests up --force-recreate --build -d
	docker run --rm -t \
		--network phpdockertemplatetests_backend-php \
		-v "${current_dir}/test:/tests" \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		renatomefi/docker-testinfra:latest --verbose --hosts='docker://phpdockertemplatetests_php_fpm_1'
	docker run --rm -t \
		--network phpdockertemplatetests_backend-php \
		-v "${current_dir}/test:/tests" \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		renatomefi/docker-testinfra:latest --verbose --hosts='docker://phpdockertemplatetests_nginx_1'
	docker-compose -p php-docker-template-tests down
