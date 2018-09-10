# 2. Nginx configuration is shaped for PHP fpm needs

Date: 2018-09-10

## Status

Accepted

## Context

Nginx is a webserver which can work on many ways, from proxy, to reverse proxy, load balancer and traditional web server.
We need a configuration which suits the need for PHP fpm under sockets

## Decision

The default configuration and custom variables will be shaped for PHP fpm needs, allowing an easy plug-and-play for these kind of projects.
This includes using a shared PHP fpm socket under `/var/run`.

## Consequences

The known consequences are:

- A shared volume between PHP fpm and Nginx containers must be created, impacting Docker Compose, kubernetes or any other orchestration tools of these images. Also making local `Docker run` less trivial to work.
- Nginx by default will *not* have access to PHP code, meaning you can't serve static files via the nginx container.
- All requests are redirected to the fpm container, even the most trivial ones i.e.: `favicon.png`
- Any customization of the items above will have to replace the whole `vhost.conf`, which will have to live in the project's repository and be maintained there. Thus we can't guarantee the tests here are covering the custom usage of the images.
