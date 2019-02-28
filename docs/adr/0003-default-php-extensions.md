# 3. Default PHP Extensions

Date: 2019-02-27

## Status

Accepted

## Context

Given the premise that those images are designed to run in production, in a clustered environment and managed by an orchestrator like Kubernetes or Docker Swarm, it becomes necessary to shape the PHP installation towards those needs.

For instance, images that ship without any PHP extensions (like the official ones) are not able to handle posix signals (like `SIGTERM` or `SIGINT`) from an orchestrator. Moreover they lack in-memory user cache, which can be useful for projecting data into a service.

## Decision

Ship the Docker images with extensions that contribute to the vision of the microservices use case, being:

- `PCNTL` in order to deal with user signals. [PCNTL Manual page](http://php.net/manual/en/book.pcntl.php)
  - This is meant for long running non-interactive php applications. `fpm` is not impacted, since it [can deal with these signals natively](https://linux.die.net/man/8/php-fpm).
- `APCU` in order to provide a user in-memory caching namespace. [APCU Manual page](http://php.net/manual/en/book.apcu.php)
- `OPcache` for PHP bytecode cache, given the Docker image immutability principle it's good not to re-parse the code. [OPcache Manual page](http://php.net/manual/en/book.opcache.php)

## Consequences

- Some of those extensions are not easy to disable, being less flexible for other use cases and becoming more opinionated
- The images are bigger (Kilobytes)
