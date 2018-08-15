push: push-cli-dev push-cli push-http-dev push-http
build: build-cli-dev build-cli build-http-dev build-http build-fpm build-fpm-dev
ci-push-cli: ci-docker-login push-cli-dev push-cli
ci-push-http: ci-docker-login push-http-dev push-http

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

.PHONY: *

# Docker image builds
build-cli-dev:
	docker build -t usabillabv/php-base:cli-dev -f Dockerfile-cli --target=cli-dev .
build-cli:
	docker build -t usabillabv/php-base:cli -f Dockerfile-cli --target=cli .
build-http-dev:
	docker build -t usabillabv/php-base:http-dev -f Dockerfile-http --target=http-dev .
build-http:
	docker build -t usabillabv/php-base:http -f Dockerfile-http --target=http .
build-fpm-dev:
	docker build -t usabillabv/php-base:fpm-dev -f Dockerfile-fpm --target=fpm-dev .
build-fpm:
	docker build -t usabillabv/php-base:fpm -f Dockerfile-fpm --target=fpm .

# Docker image push
push-cli-dev: build-cli-dev
	docker push usabillabv/php-base:cli-dev
push-cli: build-cli
	docker push usabillabv/php-base:cli
push-http-dev: build-http-dev
	docker push usabillabv/php-base:http-dev
push-http: build-http
	docker push usabillabv/php-base:http
push-fpm-dev: build-fpm-dev
	docker push usabillabv/php-base:fpm-dev
push-fpm: build-fpm
	docker push usabillabv/php-base:fpm

# CI dependencies
ci-docker-login:
	docker login --username $$DOCKER_USER --password $$DOCKER_PASSWORD

test:
	docker-compose -p php-docker-template-tests up -d
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
