build: clean-tags build-cli build-fpm build-http
push: build push-cli build-fpm push-http
ci-push-cli: ci-docker-login push-cli
ci-push-fpm: ci-docker-login push-fpm
ci-push-http: ci-docker-login push-http
ci-test: ci-test-cli ci-test-fpm
qa: lint lint-shell build test scan-vulnerability

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

.PHONY: *

BUILDINGIMAGE=*

# Docker PHP images build matrix ./build-php.sh (cli/fpm) (PHP version) (Alpine version)
build-cli: BUILDINGIMAGE=cli
build-cli: clean-tags
	./build-php.sh cli 7.2 3.7
	./build-php.sh cli 7.2 3.8
	./build-php.sh cli 7.2 3.9
	./build-php.sh cli 7.3 3.8
	./build-php.sh cli 7.3 3.9

build-fpm: BUILDINGIMAGE=fpm
build-fpm: clean-tags
	./build-php.sh fpm 7.2 3.7
	./build-php.sh fpm 7.2 3.8
	./build-php.sh fpm 7.2 3.9
	./build-php.sh fpm 7.3 3.8
	./build-php.sh fpm 7.3 3.9

# Docker HTTP images build matrix ./build-nginx.sh (nginx version) (extra tag)
build-http: BUILDINGIMAGE=http
build-http: clean-tags
	./build-nginx.sh 1.15 nginx # nginx v1.5 is currently carrying the `nginx` tag but so far we only tested 1.14
	./build-nginx.sh 1.14

.NOTPARALLEL: clean-tags
clean-tags: 
	rm ${current_dir}/tmp/build-${BUILDINGIMAGE}.tags || true

# Docker images push
push-cli: BUILDINGIMAGE=cli
push-cli:
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %
push-fpm: BUILDINGIMAGE=fpm
push-fpm:
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %
push-http: BUILDINGIMAGE=http
push-http:
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %

# CI dependencies
ci-docker-login:
	docker login --username $$DOCKER_USER --password $$DOCKER_PASSWORD

lint:
	docker run -v ${current_dir}:/project:ro --workdir=/project --rm -it hadolint/hadolint:latest-debian hadolint /project/Dockerfile-cli /project/Dockerfile-fpm /project/Dockerfile-http

lint-shell:
	docker run --rm -v ${current_dir}:/mnt:ro koalaman/shellcheck src/http/nginx/docker* src/php/utils/install-* src/php/utils/docker/* build* test-*

test-cli: ./tmp/build-cli.tags
	xargs -I % ./test-cli.sh % < ./tmp/build-cli.tags

DOCKER_TEST_RUN=docker run --rm -t \
	--network php-docker-template-tests_backend-php \
	-v "${current_dir}/test:/tests" \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	renatomefi/docker-testinfra:2 --verbose

test:
	docker-compose -p php-docker-template-tests up --force-recreate --build -d \
		|| (docker-compose -p php-docker-template-tests down; echo "tests failed" && exit 1)
	$(DOCKER_TEST_RUN) --hosts='docker://php-docker-template-tests_php_fpm_1' \
		-m "php or php_fpm or php_no_dev and not php_dev" \
		|| (docker-compose -p php-docker-template-tests down; echo "tests failed" && exit 1)
	$(DOCKER_TEST_RUN) --hosts='docker://php-docker-template-tests_php_fpm_dev_1' \
		-m "php or php_dev" \
		|| (docker-compose -p php-docker-template-tests down; echo "tests failed" && exit 1)
	$(DOCKER_TEST_RUN) --hosts='docker://php-docker-template-tests_php_cli_1' \
		-m "php or php_cli or php_no_dev and not php_dev" \
		|| (docker-compose -p php-docker-template-tests down; echo "tests failed" && exit 1)
	$(DOCKER_TEST_RUN) --hosts='docker://php-docker-template-tests_php_cli_dev_1' \
		-m "php or php_cli or php_dev" \
		|| (docker-compose -p php-docker-template-tests down; echo "tests failed" && exit 1)
	$(DOCKER_TEST_RUN) --hosts='docker://php-docker-template-tests_nginx_1' \
		-m "nginx" \
		|| (docker-compose -p php-docker-template-tests down; echo "tests failed" && exit 1)
	docker-compose -p php-docker-template-tests down

ci-test-fpm:
	docker-compose -p php-docker-template-tests up --force-recreate -d
	$(DOCKER_TEST_RUN) --hosts='docker://php-docker-template-tests_php_fpm_1' \
		-m "php or php_fpm or php_no_dev and not php_dev" --junitxml=/tests/test-results/php-fpm.xml
	$(DOCKER_TEST_RUN) --hosts='docker://php-docker-template-tests_php_fpm_dev_1' \
		-m "php or php_dev" --junitxml=/tests/test-results/php-fpm.xml
	$(DOCKER_TEST_RUN) --hosts='docker://php-docker-template-tests_nginx_1' \
		-m nginx --junitxml=/tests/test-results/nginx.xml

scan-vulnerability:
	docker-compose -f test/security/docker-compose.yml -p clair-ci up -d
	RETRIES=0 && while ! wget -T 10 -q -O /dev/null http://localhost:6060/v1/namespaces ; do sleep 1 ; echo -n "." ; if [ $${RETRIES} -eq 10 ] ; then echo " Timeout, aborting." ; exit 1 ; fi ; RETRIES=$$(($${RETRIES}+1)) ; done
	mkdir -p ./tmp/clair/usabillabv
	cat ./tmp/build-*.tags | xargs -I % sh -c 'clair-scanner --ip 172.17.0.1 -r "./tmp/clair/%.json" -l ./tmp/clair/clair.log % || echo "% is vulnerable"'
	docker-compose -f test/security/docker-compose.yml -p clair-ci down

ci-scan-vulnerability:
	docker-compose -f test/security/docker-compose.yml -p clair-ci up -d
	RETRIES=0 && while ! wget -T 10 -q -O /dev/null http://localhost:6060/v1/namespaces ; do sleep 1 ; echo -n "." ; if [ $${RETRIES} -eq 10 ] ; then echo " Timeout, aborting." ; exit 1 ; fi ; RETRIES=$$(($${RETRIES}+1)) ; done
	mkdir -p ./tmp/clair/usabillabv
	cat ./tmp/build-*.tags | xargs -I % sh -c 'clair-scanner --ip 172.17.0.1 -r "./tmp/clair/%.json" -l ./tmp/clair/clair.log %'; \
	XARGS_EXIT=$$?; \
	if [ $${XARGS_EXIT} -eq 123 ]; then find ./tmp/clair/usabillabv -type f | sed 's/^/-Fjson=@/' | xargs -d'\n' curl -X POST ${WALLE_REPORT_URL} -F channel=team_oz -F buildUrl=https://circleci.com/gh/usabilla/php-docker-template/${CIRCLE_BUILD_NUM}#artifacts/containers/0; else exit $${XARGS_EXIT}; fi	
