# PHP Docker images template

[![Usabilla Logo](https://usabilla.com/img/usabilla-logo-circle.svg)](https://usabilla.com/)

[![CircleCI](https://circleci.com/gh/usabilla/php-docker-template.svg?style=svg)](https://circleci.com/gh/usabilla/php-docker-template)
[![Docker hub](https://img.shields.io/badge/Docker%20Hub-00a5c9.svg?logo=docker&style=flat&color=00a5c9&labelColor=00a5c9&logoColor=white)](https://hub.docker.com/r/usabillabv/php/)
[![Docker hub](https://img.shields.io/docker/pulls/usabillabv/php.svg?color=00a5c9&labelColor=03566a)](https://hub.docker.com/r/usabillabv/php/)
[![Docker hub](https://img.shields.io/microbadger/image-size/usabillabv/php/7.3-fpm-alpine3.11.svg?color=00a5c9&labelColor=03566a)](https://hub.docker.com/r/usabillabv/php/)
[![Usabilla Feedback Button](.github/static/img/badge-usabilla-leave-us-feedback.png)](https://d6tizftlrpuof.cloudfront.net/live/i/4f03f8e795fb10233e000000/50db3123f698e9156665fa0fb1a914932de5a334.html?reset&project=php-docker-template&source=github)

A series of Docker images to run PHP Applications on Usabilla Style

- [Using and extending](#using-and-extending)
  - [Nginx](#for-nginx-customization)
  - [PHP](#for-php-customization)
    - [Healthcheck](#php-fpm-healthcheck)
- [Architecture Decisions Records](#architecture-decisions-records)
- [Basic architecture](#basic-architecture)
- [The base images](#the-base-images)
- [Alpine Linux situation](#alpine-linux-situation)
- [The available tags](#the-available-tags)
- [Adding more supported versions](#adding-more-supported-versions)
- [Prometheus Exporter](#prometheus-exporter)
- [Dockerfile example with Buildkit](#dockerfile-example)
- [PHP FPM functional example](docs/examples/hello-world-fpm)
- [Contributing](.github/CONTRIBUTING.md)
- [License](LICENSE.md)

## Architecture Decisions Records

This project adheres to ADRs, a [list can be found here](docs/adr/).

## Version Support Policy

Our policy on versions we support [is outlined in ADR0005](docs/adr/0005-define-a-policy-for-supported-versions-and-upgrades.md).

## Basic architecture

All being based on the official images we provide:

- PHP cli - Compiled without php-fpm, a simple php binary image
- PHP fpm - Specifically designed to share the php-fpm socket towards a fastcgi compliant web sever
- Nginx - Meant for PHP projects built on the PHP FPM image in this repository, since [it looks for a php-fpm socket
and doesn't have access to the PHP code](docs/adr/0002-nginx-configuration-is-shaped-for-php-needs.md)

The fpm/HTTP server relationship:

```text
+------------------------------+-----+            +--------------------+
|                              | :80 |            |                    |
|  FastCGI HTTP container      +-----+            |  PHP fpm container |
|                                    |            |                    |
|                                    |            |                    |
|       +-------------------------+  |            |  +--------------+  |
|       |  /var/run/php|fpm.sock  |<--------------+  |  Source code |  |
|       +-------------------------+  |            |  +--------------+  |
|                                    |            |                    |
+------------------------------------+            +--------------------+
```

### Extra software

- PHP
  - Shush - Used for decrypting our secret variables using AWS KMS
  - composer - To provide the installation of PHP projects
- Nginx
  - A location.d helper to enable/disable custom location configuration

## The base images

All images are based on their official variants, being:

- [PHP official image](https://hub.docker.com/_/php/)
- [Nginx official image](https://hub.docker.com/_/alpine/)
- Both PHP and Nginx images are based on [Alpine Linux](https://hub.docker.com/_/alpine/)

## Alpine Linux situation

Even though both of the images are based on the Alpine Linux, the PHP official repository gives us the option to choose
between its versions, at this moment being `3.9` or `3.10`.

Meanwhile on the official Nginx images we have no control over which Alpine version we use, this explains the tagging
strategy coming in the next section.

## The available tags

The docker registry prefix is `usabillabv/php`, thus `usabillabv/php:OUR-TAGS`.

In order to provide upgrade path we intend to keep one or more versions of PHP and Nginx.

[Currently Available tags on Docker hub](https://hub.docker.com/r/usabillabv/php/tags/)

The tag naming strategy consists of (Read as a regex):

- PHP: `(phpMajor).(phpMinor)-(cli|fpm)-(alpine|future supported OSes)(alpineMajor).(alpineMinor)(-dev)?`
  - Example: `7.3-fpm-alpine3.11`, `7.3-fpm-alpine3.11-dev`
  - Note: The minor version might come followed by special versioning constraints in case of betas, etc. For instance
   `7.3-rc-fpm-alpine3.11-dev`
- Nginx: `nginx(major).(minor)(-dev)?`
  - Example: `nginx1.15`, `nginx1.15-dev`

## Adding more supported versions

The whole CI/CD pipeline is centralized in Makefile targets, the build of cli, fpm and http (for now only nginx) images
have their targets named as `build-cli`, `build-fpm` and `build-http`.

With the help of building scripts the addition of new versions is as easy as updating the Makefile with the desired new
version.

All the newly built versions are going to be automatically tagged and pushed upon CI/CD success, to see the output of
your new changes you can see the `(BUILD).tags` file in the `tmp` directory.

### PHP

In this example adding PHP 7.4-rc for cli and fpm:

```diff
build-cli: clean-tags
	./build-php.sh cli 7.4 3.10
	./build-php.sh cli 7.4 3.11
+	./build-php.sh cli 7.4-rc 3.12

build-fpm: clean-tags
	./build-php.sh fpm 7.4 3.10
	./build-php.sh fpm 7.4 3.11
+	./build-php.sh fpm 7.4-rc 3.12
```

Being `./build-php.sh (cli/fpm) (PHP version) (Alpine version)`

### Nginx

In this example adding Nginx 1.16:

```diff
build-http: clean-tags
    ./build-nginx.sh 1.15 nginx
    ./build-nginx.sh 1.14
+   ./build-nginx.sh 1.16
```

Being `./build-nginx.sh (nginx version) (extra tag)`

Note you can add extra tags, this means if you want to make Nginx 1.16 our new default version you have to:

```diff
build-http: clean-tags
-   ./build-nginx.sh 1.15 nginx
+   ./build-nginx.sh 1.15
    ./build-nginx.sh 1.14
-   ./build-nginx.sh 1.16
+   ./build-nginx.sh 1.16 nginx
```

### Important

Removing a version from the build will not remove it from the Docker registry, this has to be done manually when desired.

## Using and extending

### PHP FPM healthcheck

This image ships with the [php-fpm-healthcheck](https://github.com/renatomefi/php-fpm-healthcheck) which allows you to
healthcheck FPM independently of the Nginx setup, providing more compatibility with [the single process Docker
container](https://cloud.google.com/solutions/best-practices-for-building-containers#package_a_single_app_per_container).

This healthcheck provides diverse metrics to watch and can be configured according to your needs.
More information on how to use it can be found in the
[official documentation](https://github.com/renatomefi/php-fpm-healthcheck#a-php-fpm-health-check-script).

The healthcheck can be found in the container `$PATH` as an executable:

```console
$ php-fpm-healthcheck
$ echo $?
0
```

## Basic usage

Simply use the images as base of the application's `Dockerfile` and apply the necessary changes.

```Dockerfile
# syntax=docker/dockerfile:1.0.0-experimental

FROM usabillabv/php:7.4-fpm-alpine3.12
```

In usual cases it might not be necessary to extend the nginx images, unless you desire to extend its behavior, for
instance to serve static files.

[Nginx customization](#for-nginx-customization)

[PHP customization](#for-php-customization)

## For Nginx customization

### Document root configuration

Nginx is configured with only one virtual host, which is using `/opt/project/public` as the document root. Ideally we
should change this configuration to point to the `public` directory of our project, so that we expose only what's
necessary.

In order to do this you should override `NGINX_DOCUMENT_ROOT` environment variable in the `Dockerfile`, e.g.:  

```Dockerfile
# assuming that your project is mounted/copied to `/project` and it has a public
# directory...

ENV NGINX_DOCUMENT_ROOT="/project/public"
```

### Server name configuration

The default server name is `localhost` and that can also be overridden using an environment variable
(`NGINX_SERVER_NAME`) in the `Dockerfile`, e.g.:

```Dockerfile
ENV NGINX_SERVER_NAME="myawesomeservice myawesomeservice.usabilla.com"
```

### Workers

To use the most of your server you can tweak the number of nginx workers and connections accepted by them, the default
values are (respectively): `1` and `1024`.

These values can be overridden using environment variables (`NGINX_WORKERS_PROCESSES` and `NGINX_WORKERS_CONNECTIONS`)
in the `Dockerfile`, e.g.:

```Dockerfile
ENV NGINX_WORKERS_PROCESSES="4"
ENV NGINX_WORKERS_CONNECTIONS="2048"
```

Documentation for [worker_processes](http://nginx.org/en/docs/ngx_core_module.html#worker_processes)
and [worker_connections](http://nginx.org/en/docs/ngx_core_module.html#worker_connections).

### Connection keep alive timeout

The default `keepalive_timeout` is `75` and that can also be overridden using an environment variable
(`NGINX_KEEPALIVE_TIMEOUT`) in the `Dockerfile`, e.g.:

```Dockerfile
ENV NGINX_KEEPALIVE_TIMEOUT="30"
```

More about it in the [Official documentation](http://nginx.org/en/docs/http/ngx_http_core_module.html#keepalive_timeout).

### Client body buffer size

The default `client_body_buffer_size` is `8k|16k` (depending on architecture), having it configurable helps to not
create disk body buffers in apps that don't splitting it, e.g.:

```Dockerfile
ENV NGINX_CLIENT_BODY_BUFFER_SIZE="64k"
```

More about it in the [Official documentation](http://nginx.org/en/docs/http/ngx_http_core_module.html#client_body_buffer_size).

### Client max body size

The default `client_max_body_size` is `1m`, you can increase it in case of
larger payloads, e.g.:

```Dockerfile
ENV NGINX_CLIENT_MAX_BODY_SIZE="8m"
```

More about it in the [Official documentation](http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size).

### Large client header buffers

The default `large_client_header_buffers` is `4 8k`, being `number size` you can
increase it in case of larger header payloads, e.g.:

```Dockerfile
ENV NGINX_LARGE_CLIENT_HEADER_BUFFERS="8 128k"
```

More about it in the [Official documentation](http://nginx.org/en/docs/http/ngx_http_core_module.html#large_client_header_buffers).

### Expose Nginx version

By default we are not exposing the nginx version in the `Server` header, that
can also be overridden using an environment variable (`NGINX_EXPOSE_VERSION`)
in the `Dockerfile`, e.g.:

```Dockerfile
ENV NGINX_EXPOSE_VERSION="on"
```

### Cors configuration

There's a CORS helper available, it can be activated by running:

```console
$ docker-nginx-location.d-enable cors

```

Or by setting an environment variable:

```Dockerfile
ENV NGINX_CORS_ENABLE=true
```

It's also possible to customize the `Allow-Origin` but setting an environment variable in the `Dockerfile`, e.g.:

```Dockerfile
ENV NGINX_CORS_ALLOW_ORIGIN="https://my-domain.cool"
```

## For PHP customization

### PHP-FPM Configuration

To allow tuning the FPM pool, some pool directives are configurable via the following environment variables.
For more information on these directives, see [the documentation](https://www.php.net/manual/en/install.fpm.configuration.php).

| Directive               | Environment Variable            | Default                 |
|-------------------------|---------------------------------|-------------------------|
| pm                      | PHP_FPM_PM                      | dynamic                 |
| pm.max_children         | PHP_FPM_PM_MAX_CHILDREN         | 5                       |
| pm.start_servers        | PHP_FPM_PM_START_SERVERS        | 2                       |
| pm.min_spare_servers    | PHP_FPM_PM_MIN_SPARE_SERVERS    | 1                       |
| pm.max_spare_servers    | PHP_FPM_PM_MAX_SPARE_SERVERS    | 3                       |
| pm.process_idle_timeout | PHP_FPM_PM_PROCESS_IDLE_TIMEOUT | 10                      |
| pm.max_requests         | PHP_FPM_PM_MAX_REQUESTS         | 0                       |
| access.format           | PHP_FPM_ACCESS_FORMAT           | %R - %u %t \"%m %r\" %s |

An example Dockerfile with customized configuration might look like:

```Dockerfile
# syntax=docker/dockerfile:1.0.0-experimental

FROM usabillabv/php:7.3-fpm-alpine3.11

ENV PHP_FPM_PM="static"
ENV PHP_FPM_PM_MAX_CHILDREN="70"
ENV PHP_FPM_PM_START_SERVERS="10"
ENV PHP_FPM_PM_MIN_SPARE_SERVERS="20"
ENV PHP_FPM_PM_MAX_SPARE_SERVERS="40" 
ENV PHP_FPM_PM_PROCESS_IDLE_TIMEOUT="35"
ENV PHP_FPM_PM_MAX_REQUESTS="500"
ENV PHP_FPM_ACCESS_FORMAT {\\\"cpu_usage\\\":%C,\\\"memory_usage\\\":%M,\\\"duration_microsecond\\\":%d,\\\"script\\\":\\\"%f\\\",\\\"content_length\\\":%l,\\\"request_method\\\":\\\"%m\\\",\\\"pool_name\\\":\\\"%n\\\",\\\"process_id\\\":\\\"%p\\\",\\\"request_query_string\\\":\\\"%q\\\",\\\"request_uri_query_string_glue\\\":\\\"%Q\\\",\\\"request_uri\\\":\\\"%r\\\",\\\"request_url\\\":\\\"%r%Q%q\\\",\\\"remote_ip_address\\\":\\\"%R\\\",\\\"response_status_code\\\":%s,\\\"time\\\":\\\"%t\\\",\\\"remote_user\\\":\\\"%u\\\"}
```

### PHP configuration

The official PHP images ship with recommended
[`ini` configuration files](https://github.com/docker-library/docs/tree/master/php#configuration) for both
development and production. In order to guarantee a reasonable configuration, our images load these files by default
in each image respectively at this path: `$PHP_INI_DIR/php.ini`.

Images that wish to extend the ones provided in this repository can override these configurations easily by including
customized configuration files in the `$PHP_INI_DIR/conf.d/` directory.

### Installing & enabling PHP extensions

This image bundles helper scripts to manage PHP extensions (`docker-php-ext-configure`, `docker-php-ext-install`, and
`docker-php-ext-enable`), so it's quite simple to install core and PECL extensions.

More about it in the [Official Documentation](https://github.com/docker-library/docs/blob/master/php/README.md#how-to-install-more-php-extensions).

#### PHP Core extensions

To install a core extension that doesn't require any change in the way PHP is compiled you only need to use
`docker-php-ext-install`, which will compile the extra extension and enable it.

To do it should include something like this to your `Dockerfile`:

```Dockerfile
# Enables opcache:
RUN set -x \
    && apk add --no-cache gnupg \
    && docker-php-source-tarball download \
    && docker-php-ext-install opcache \
    && docker-php-source-tarball delete

# Installs PDO driver for PostgreSQL (temporarily adding postgresql-dev to have
# the necessary C libraries):
RUN set -x \
    && apk add --no-cache gnupg postgresql-client postgresql-dev \
    && docker-php-source-tarball download \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-source-tarball delete \
    && apk del gnupg postgresql-dev
```

Some core extensions, like GD, requires changes to PHP compilation. For that you
should also use `docker-php-ext-configure`, e.g.:

```Dockerfile
# Installs GD extension and the required libraries: 
RUN set -x \
    apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd
```

#### PECL extensions

Some extensions are not provided with the PHP source, but are instead available through [PECL](https://pecl.php.net/),
see a full list of them [here](https://pecl.php.net/packages.php).

To install a PECL extension, use `pecl install` to download and compile it, then use `docker-php-ext-enable` to enable
it:

```Dockerfile
# Installs ast extension (temporarily adding the necessary libraries):
RUN set -x \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && pecl install ast \
    && docker-php-ext-enable ast \
    && apk del .phpize-deps
```

Check if the extension is loaded after building it:

```console
$ docker build .
Successfully built 5bcf0f7d49b0
$ docker run --rm 5bcf0f7d49b0 php -m | grep ast
ast
```

```Dockerfile
# Installs MongoDB Driver (temporarily adding the necessary libraries):
RUN set -x \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS openssl-dev  \
    && pecl install mongodb-1.5.3 \
    && docker-php-ext-enable mongodb \
    && apk del .build-deps
```

#### Common extension helper scripts

Some extensions are used across multiple projects but can have some complexities while installing so we ship helper
scripts with the PHP images to install dependencies and enable the extension. The following helper scripts can be run
inside projects' Dockerfile:

- `docker-php-ext-rdkafka` for RD Kafka
- `docker-php-ext-pdo-pgsql` for PDO Postgres

#### Xdebug

Since [Xdebug](https://xdebug.org) is a common extension to be used we offer two options:

##### Dev image

Use the `dev` image by appending `-dev` to the end of the tag, like: `usabillabv/php:7.3-fpm-alpine3.11-dev`.

Not recommended if you're layering with your production images, using a different base image doesn't allow to you share
cache among your Dockerfile targets.

We ship the image with a dev mode helper, which can install and configure Xdebug, as well as override the production
`php.ini` with the recommended development version.

##### Helper script

Installing and enabling the extensions

```console
$ docker-php-dev-mode xdebug
```

As mentioned, we override the production `php.ini` with the recommended development version, which can be found
[here](https://github.com/php/php-src/blob/master/php.ini-development).

Next to that we provide some additional configuration to make it easier to start your debugging session. The contents
of that configuration can be found [here](src/php/conf/available/xdebug.ini).

Both are enabled via the helper script, by running

```console
$ docker-php-dev-mode config
```

##### Setting up Xdebug

Xdebug 3 comes with new mechanism to enable it's functionalities. The most notable, is the introduction of the 
`xdebug.mode` setting, which controls which features are enabled. It can be specified via `.ini` files or by using the 
environment variable `XDEBUG_MODE`. To learn more about the different modes in which Xdebug can be configured, please 
refer to the [Xdebug settings guide](https://xdebug.org/docs/all_settings#mode).

##### Notable changes from Xdebug 2

With the introduction of the Xdebug mode in the v3 release, it is now mandatory to specify either `xdebug.mode=coverage` setting in .ini 
file, or `XDEBUG_MODE=coverage` as environment variable, to use the code coverage analysis features. This impacts tools 
like mutation tests.

We recommend setting the XDEBUG_MODE when booting up a new container. Here's an example on how it could look like:

```shell
docker run -it \
  -e XDEBUG_MODE=coverage \
  -v "<HOST_PATH>:<CONTAINER_PATH>" \
  usabillabv/php:7.4-cli-alpine3.12-dev \
  vendor/bin/infection --test-framework-options='--testsuite=unit' -s --threads=12 --min-msi=100 --min-covered-msi=100
```

Another notable change, is the Xdebug port change. The default port is now `9003` instead of `9000`. Check your IDE 
settings to confirm the correct port is specified. 

For the full upgrade guide, please refer to the [official upgrade guide](https://xdebug.org/docs/upgrade_guide).

## Prometheus Exporter

In order to monitor applications many systems implement Prometheus to expose metrics, one challenge specially in PHP is how to expose those to Prometheus without having to, either implement an endpoint in our application, or add HTTP and an endpoint for non-interactive containers.

This prove has the aim to provide support for the sidecar pattern for monitoring.

More about ["Make your application easy to monitor" by Google](https://cloud.google.com/solutions/best-practices-for-operating-containers#make_your_application_easy_to_monitor)

### Static File

The easiest way to solve this problem in the PHP ecosystem is to make your application write down the metrics to a text file, which then is shared via a volume to a sidecar container which can expose it to Prometheus.

The container we offer is a simple Nginx based on the same configuration as [the one for PHP-FPM](#for-nginx-customization), with the difference it only serves static content.

#### Docker image

The image named `prometheus-exporter-file` is available via our docker registry under with the tags (from less to more specific versions):

- `usabillabv/php:prometheus-exporter-file` - This has the behavior of latest
- `usabillabv/php:prometheus-exporter-file1`
- `usabillabv/php:prometheus-exporter-file1.0`

#### Kubernetes Deployment Example

```yaml
# Pod v1 core Spec - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#pod-v1-core

spec:
  template:
    metadata:
      annotations:
        prometheus.io/path: /metrics
        prometheus.io/port: "5556"
        prometheus.io/scrape: "true"
    spec:
      containers:
      - image: usabillabv/php:7.3-cli-alpine3.11
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - mountPath: /prometheus
          name: prometheus-metrics
      - image: usabillabv/php:prometheus-exporter-file1
        imagePullPolicy: IfNotPresent
        name: prometheus-exporter
        env:
        - name: NGINX_PORT
          value: "5556"
        ports:
        - containerPort: 5556
          name: http
          protocol: TCP
        volumeMounts:
        - mountPath: /opt/project/public
          name: prometheus-metrics
      volumes:
      - emptyDir: {}
        name: prometheus-metrics

```

In this example the PHP container *must* write down the metrics in the file `/prometheus/metrics`, the exporter container will have the same file mount at `/opt/project/public/metrics`.
Which will then be available via http as `http://pod:5556/metrics`, observe that the filename becomes the url which we configured the prometheus scrape to look for.

### Open Census

_To be created and/or documented_

For now please refer to: https://github.com/basvanbeek/opencensus-php-docker and https://github.com/census-instrumentation/opencensus-php

## Dockerfile example

The Dockerfile in the example below is meant to centralize the production and development images in a single Dockerfile,
sharing cached layers among the build steps, cleaning unnecessary files like tests, docs and readme files from the final
result via git archive.

Composer auth is done via a secret mount to avoid layering credentials and keeping the layers lean.

We also run the image with the `app` user since doing it as `root` is considered a bad practice.

To be able to build this image you need [Docker buildkit](https://github.com/moby/buildkit) enabled, this is what
empowers the `RUN` mounts and more, check its documentation
[here](https://docs.docker.com/develop/develop-images/build_enhancements/).

```Dockerfile
# syntax=docker/dockerfile:1.0.0-experimental

# The base target will serve as initial layer for dev and prod images,
# thus all necessary global configurations, extensions and modules
# should be put here
FROM usabillabv/php:7.3-fpm-alpine3.11 AS base

# When composer gets copied we want to make sure it's from the major version 1
FROM composer:1 as composer

# The source target is responsible to prepare the source code by cleaning it and
# installing the necessary dependencies, it's later copied into the production
# target, which then leaves no traces of the build process behind whilst making
# the image lean
FROM base as source

ENV COMPOSER_HOME=/opt/.composer

RUN apk add --no-cache git

COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /opt/archived

# Mount the current directory at `/opt/project` and run git archive
# hadolint ignore=SC2215
RUN --mount=type=bind,source=./,rw \
    mkdir -p /opt/project \
    && git archive --verbose --format tar HEAD | tar -x -C /opt/project

WORKDIR /opt/project

# Mount composer.auth to the project root and composer cache if available
# then install the dependencies
# hadolint ignore=SC2215
RUN --mount=type=secret,id=composer.auth,target=/opt/project/auth.json \
    --mount=type=bind,source=.composer/cache,target=/opt/.composer/cache \
    composer install --no-interaction --no-progress --no-dev --prefer-dist --classmap-authoritative

# Copy the source from its target and prepare permissions
FROM base as prod

WORKDIR /opt/project

COPY --chown=app:app --from=source /opt/project /opt/project

# Install Xdebug and enable development specific configuration
# also create a volume for the project which will later be mount via run
FROM base AS dev

COPY --chown=app:app --from=composer /usr/bin/composer /usr/bin/composer

RUN docker-php-dev-mode xdebug \
    && docker-php-dev-mode config

VOLUME [ "/opt/project" ]

```

### Building this image as dev

```console
$ DOCKER_BUILDKIT=1 docker build -t "my-project-dev:latest" \
  --target=dev .
```

### Building this image as prod

You want to run this in your CI/CD environment, you can create the `composer.auth` file there, for this example let's
get your computer's file and mount the secret.

```console
$ cp ~/.config/composer/auth.json .composer-auth.json
$ DOCKER_BUILDKIT=1 docker build -t "my-project-prod:latest" \
  --target=prod \
  --secret id=composer.auth,src=.composer-auth.json
```

### Working example

We also have a simple, but fully functional PHP FPM example, [check it here](docs/examples/hello-world-fpm).
