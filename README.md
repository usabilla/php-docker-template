# PHP docker template

A base image for PHP application that provides a webserver instead of only the
`php-fpm` process.

## What's installed

It's created from Alpine Linux (3.6) and bundles: 

- PHP 7.1.11 based on the [official image](https://hub.docker.com/_/php/)
- Nginx 1.13.6 based on the [official image](https://hub.docker.com/_/nginx/)
- Supervisord 3.2

## Using and extending

Simply use this as image base of the application's `Dockerfile` and apply the
necessary changes.


### Document root configuration

Nginx is configured with only one virtual host, which is using `/var/www/html`
as document root. Ideally we should change this configuration to point to the
`public` folder of our project, so that we expose only what's necessary.

In order to do this you should override `NGINX_DOCUMENT_ROOT` environment
variable in the `Dockerfile`, e.g.:  

```Dockerfile
# assuming that your project is mounted/copied to `/project` and it has a public
# folder...

ENV NGINX_DOCUMENT_ROOT="/project/public"
```

### Server name configuration 

The default server name is `localhost` and that can also be overridden using an
environment variable (`NGINX_SERVER_NAME`) in the `Dockerfile`, e.g.:  

```Dockerfile
ENV NGINX_SERVER_NAME="myawesomeservice myawesomeservice.usabilla.com"
```

### Installing & enabling PHP extensions

This image bundles the same scripts available in the official PHP images to
manage PHP extensions (`docker-php-ext-configure`, `docker-php-ext-install`, and
`docker-php-ext-enable`), so it's quite simple to install core and PECL
extensions.

#### Core extensions

To install a core extension that doesn't require any change on the way PHP was
compiled you only need to use `docker-php-ext-install`, which will compile the
extra extension and enable it. To do it should include something like this to 
your `Dockerfile`:

```Dockerfile
# Enables opcache:
RUN docker-php-ext-install opcache

# Installs PDO driver for PostgreSQL (temporarily adding postgresql-dev to have
# the necessary C libraries):
RUN apk add --no-cache postgresql-client postgresql-dev \
    && docker-php-ext-install pdo_pgsql \
    && apk del postgresql-dev
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

