qa: lint lint-shell build test scan-vulnerability
build: clean-tags build-cli build-fpm build-http build-prometheus-exporter-file
push: build push-cli push-fpm push-http
ci-push-cli: ci-docker-login push-cli
ci-push-fpm: ci-docker-login push-fpm
ci-push-http: ci-docker-login push-http
ci-push-prometheus-exporter-file: ci-docker-login push-prometheus-exporter-file

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
	./build-php.sh cli 7.2 3.10
	./build-php.sh cli 7.3 3.8
	./build-php.sh cli 7.3 3.9
	./build-php.sh cli 7.3 3.10
	./build-php.sh cli 7.3 3.11
	./build-php.sh cli 7.4 3.10
	./build-php.sh cli 7.4 3.11
	./build-php.sh cli 7.4 3.12

build-fpm: BUILDINGIMAGE=fpm
build-fpm: clean-tags
	./build-php.sh fpm 7.2 3.7
	./build-php.sh fpm 7.2 3.8
	./build-php.sh fpm 7.2 3.9
	./build-php.sh fpm 7.2 3.10
	./build-php.sh fpm 7.3 3.8
	./build-php.sh fpm 7.3 3.9
	./build-php.sh fpm 7.3 3.10
	./build-php.sh fpm 7.3 3.11
	./build-php.sh fpm 7.4 3.10
	./build-php.sh fpm 7.4 3.11
	./build-php.sh fpm 7.4 3.12

# Docker HTTP images build matrix ./build-nginx.sh (nginx version) (extra tag)
build-http: BUILDINGIMAGE=http
build-http: clean-tags
	./build-http.sh 1.19 nginx1 nginx
	./build-http.sh 1.18

# Docker Prometheus Exporter file images build matrix ./build-prometheus-exporter-file.sh (nginx version) (extra tag)
# Adding arbitrary version 1.0 in order to make sure if we break compatibility we have to up it
build-prometheus-exporter-file: BUILDINGIMAGE=prometheus-exporter-file
build-prometheus-exporter-file: clean-tags
	./build-prometheus-exporter-file.sh 1.29 prometheus-exporter-file1.0 prometheus-exporter-file1

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
push-prometheus-exporter-file: BUILDINGIMAGE=prometheus-exporter-file
push-prometheus-exporter-file:
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %

# CI dependencies
ci-docker-login:
	docker login --username $$CONTAINER_REGISTRY_USERNAME --password $$CONTAINER_REGISTRY_PASSWORD

lint:
	docker run -v ${current_dir}:/project:ro --workdir=/project --rm -it hadolint/hadolint:latest-debian hadolint /project/Dockerfile-cli /project/Dockerfile-fpm /project/Dockerfile-http

lint-shell:
	docker run --rm -v ${current_dir}:/mnt:ro koalaman/shellcheck src/http/nginx/docker* src/php/utils/install-* src/php/utils/docker/* build* test-*

test: test-cli test-fpm test-http test-prometheus-exporter-file-e2e

test-cli: ./tmp/build-cli.tags
	xargs -I % ./test-cli.sh % < ./tmp/build-cli.tags

test-fpm: ./tmp/build-fpm.tags
	xargs -I % ./test-fpm.sh % < ./tmp/build-fpm.tags

# Test nginx with the newest and oldest fpm tags
# if it was a full matrix it'd be too many tests
test-http: ./tmp/build-http.tags ./tmp/build-fpm.tags
	xargs -I % ./test-http.sh $$(head -1 ./tmp/build-fpm.tags) % < ./tmp/build-http.tags
	xargs -I % ./test-http.sh $$(tail -1 ./tmp/build-fpm.tags) % < ./tmp/build-http.tags

test-http-e2e: ./tmp/build-http.tags
	xargs -I % ./test-http-e2e.sh % < ./tmp/build-http.tags

test-prometheus-exporter-file-e2e: ./tmp/build-prometheus-exporter-file.tags
	xargs -I % ./test-prometheus-exporter-file-e2e.sh % < ./tmp/build-prometheus-exporter-file.tags

scan-vulnerability:
	cat ./tmp/build-*.tags | xargs -I % sh -c 'docker run -v /tmp/trivy:/var/lib/trivy -v /var/run/docker.sock:/var/run/docker.sock -t aquasec/trivy:latest --cache-dir /var/lib/trivy image --skip-files "/usr/local/bin/shush" --exit-code 1 --no-progress % || (echo "% is vulnerable" && exit 1)'
