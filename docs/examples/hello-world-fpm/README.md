# Usabilla Docker PHP FPM Hello World

This is a functional example where it's possible to run Nginx and PHP FPM containers sharing sockets.

## Clone the repository

```console
$ git clone git@github.com:usabilla/php-docker-template.git
$ cd docs/examples/hello-world-fpm
```

## Start the example

We love automation, all the functionality of this demos is available via a Makefile

Do it all: Build, check and run

```console
$ make
```

The target `up` start the webserver on port `8080`, you can modify it to your needs

```console
$ make up PORT=8001
```

## Stop

The target `down` will clean up the containers for you!

It's also useful when you the `up` target fail, it might be because the port is busy

```console
$ make down
```

## Build the image

If you're modifying the `Dockerfile` you have to rebuild it via

```console
$ make docker-build
```

## More

We recommend you to read the [Makefile](./Makefile) and the [Dockerfile](./Dockerfile) to understand how things are working!

Missing anything? Feel free to open a PR or submit an issue.
