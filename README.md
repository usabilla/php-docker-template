# PHP Docker images template

A series of Docker images to run PHP Applications on Usabilla Style

## Basic architecture

All being based on the official images we provide:

- PHP cli - Compiled without php-fpm, a simple php binary image
- PHP fpm - Specifically designed to share the php-fpm socket towards a fastcgi compliant websever
- Nginx - Meant for PHP projects built on the PHP FPM image in this repository, since it looks for a php-fpm socket and doesn't have access to the PHP code

The fpm/HTTP server relationship:
```
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

Even though both of the images are based on the Alpine Linux, the PHP official repository gives us the option to choose between its versions, at this moment being `3.7` or `3.8`.

Meanwhile on the official Nginx images we have no control over which Alpine version we use, this explains the tagging strategy coming in the next section.

## The available tags

The docker registry prefix is `usabillabv/php`, thus `usabillabv/php:OUR-TAGS`

In order to provide upgrade path we intend to keep one or more versions of PHP and Nginx.

[Currently Available tags on Docker hub](https://hub.docker.com/r/usabillabv/php/tags/)

The tag naming strategy consists of (Read as a regex):

- PHP: `(phpMajor).(phpMinor)-(cli|fpm)-(alpine|future supported OSes)(alpineMajor).(alpineMinor)(-dev)?`
  - Example: `7.2-fpm-alpine3.8`, `7.2-fpm-alpine3.8-dev`
  - Note: The minor version might come followed by special versioning constraints in case of betas, etc. For instance: `7.3-rc-fpm-alpine3.8-dev`
- Nginx: `nginx(major).(minor)(-dev)?`
  - Example: `nginx1.15`, `nginx1.15-dev`

## Adding more supported versions

The whole CI/CD pipeline is centralized in Makefile targets, the build of cli, fpm and http (for now only nginx) images have their targets named as `build-cli`, `build-fpm` and `build-http`

With the help of building scripts the addition of new versions is as easy as updating the Makefile with the desired new version.

All the newly built versions are going to be automatically tagged and pushed upon CI/CD success, to see the output of your new changes you can see the `(BUILD).tags` file in the `tmp` directory

### PHP

In this example adding PHP 7.3-rc for cli and fpm:

```diff
build-cli: clean-tags
	./build-php.sh cli 7.2 3.7
	./build-php.sh cli 7.2 3.8
+	./build-php.sh cli 7.3-rc 3.8

build-fpm: clean-tags
	./build-php.sh fpm 7.2 3.7
	./build-php.sh fpm 7.2 3.8
+	./build-php.sh fpm 7.3-rc 3.8
```

Being `./build-php.sh (cli/fpm) (PHP version) (Alpine version)`

### Nginx

In this example adding Nginx 1.16:

```diff
build-http: clean-tags
	./build-nginx.sh 1.15 nginx
	./build-nginx.sh 1.14
+	./build-nginx.sh 1.16
```

Being `./build-nginx.sh (nginx version) (extra tag)`

Note you can add extra tags, this means if you want to make Nginx 1.16 our new default version you have to:

```diff
build-http: clean-tags
-	./build-nginx.sh 1.15 nginx
+	./build-nginx.sh 1.15
	./build-nginx.sh 1.14
-	./build-nginx.sh 1.16
+	./build-nginx.sh 1.16 nginx
```

### Important

Removing a version from the build won't make it be removed from Docker registry, this has to be a manual operation if desired.

## Using and extending

Simply use the images as base of the application's `Dockerfile` and apply the
necessary changes.
In usual cases it might not be necessary to extend the nginx images, unless you desired extend it's behavior by for instance serving static files.

[Nginx customization](#for-nginx-customization)

[PHP customization](#for-php-customization)

## For Nginx customization

### Document root configuration

Nginx is configured with only one virtual host, which is using `/var/www/html`
as document root. Ideally we should change this configuration to point to the
`public` directory of our project, so that we expose only what's necessary.

In order to do this you should override `NGINX_DOCUMENT_ROOT` environment
variable in the `Dockerfile`, e.g.:  

```Dockerfile
# assuming that your project is mounted/copied to `/project` and it has a public
# directory...

ENV NGINX_DOCUMENT_ROOT="/project/public"
```

### Server name configuration

The default server name is `localhost` and that can also be overridden using an
environment variable (`NGINX_SERVER_NAME`) in the `Dockerfile`, e.g.:  

```Dockerfile
ENV NGINX_SERVER_NAME="myawesomeservice myawesomeservice.usabilla.com"
```

### Workers

To use the most of your server you can tweak the number of nginx workers and
connections accepted by them, the default values are (respectively): `1` and
`1024`. These values can be overridden using environment variables (
`NGINX_WORKERS_PROCESSES` and `NGINX_WORKERS_CONNECTIONS`) in the `Dockerfile`,
e.g.:

```Dockerfile
ENV NGINX_WORKERS_PROCESSES="4"
ENV NGINX_WORKERS_CONNECTIONS="2048"
```

### Connection keep alive timeout

The default server name is `65` and that can also be overridden using an
environment variable (`NGINX_KEEPALIVE_TIMEOUT`) in the `Dockerfile`, e.g.:

```Dockerfile
ENV NGINX_KEEPALIVE_TIMEOUT="30"
```

### Client body buffer size

The default `client_body_buffer_size` is `8k|16k` (depending on architecture),
having it configurable helps to not create disk body buffers in apps that don't
splitting it, e.g.:

```Dockerfile
ENV NGINX_CLIENT_BODY_BUFFER_SIZE="64k"
```

### Expose Nginx version

By default we are not exposing the nginx version in the `Server` header, that
can also be overridden using an environment variable (`NGINX_EXPOSE_VERSION`)
in the `Dockerfile`, e.g.:

```Dockerfile
ENV NGINX_EXPOSE_VERSION="on"
```

## For PHP customization

### Installing & enabling PHP extensions

This image bundles helper scripts to manage PHP extensions (`docker-php-ext-configure`, `docker-php-ext-install`, and `docker-php-ext-enable`), so it's quite simple to install core and PECL extensions.

More about it in the [Official Documentation](https://github.com/docker-library/docs/blob/master/php/README.md#how-to-install-more-php-extensions)

#### PHP Core extensions

To install a core extension that doesn't require any change on the way PHP was
compiled you only need to use `docker-php-ext-install`, which will compile the
extra extension and enable it. To do it should include something like this to 
your `Dockerfile`:

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
RUN apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd
```

#### PECL extensions

Some extensions are not provided with the PHP source, but are instead available
through [PECL](https://pecl.php.net/). To install a PECL extension, use `pecl
install` to download and compile it, then use `docker-php-ext-enable` to enable
it:

```Dockerfile
# Installs XDebug (temporarily adding the necessary libraries):
RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del .phpize-deps
```
