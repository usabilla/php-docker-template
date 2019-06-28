# 4. Default PHP Settings - Memory Limit

Date: 2019-06-28

## Status

Accepted

## Context

This set of Docker images are opinionated and meant to run within a Docker orchestrator, kubernetes for instance.
Since most (if not all) the orchestrators have resource management built-in there are certain PHP settings which can be tweaked to make use of them, if PHP has memory limits itself, it'll die as a fatal error, in which case the orchestrator would be unaware that it's actually a out of memory situation.

## Decision

Set php ini configuration to have `memory_limit = -1`, this will affect both fpm and cli processes since it's added in the `default.ini` file of this repository.

## Consequences

- PHP won't throw a Fatal Error when it runs out of memory, rather than that the orchestrator will kill the process, effectively it is the same since PHP does not provide shutdown behavior when it runs out of memory.
- If a user of these Docker images needs a defined php memory limit, they have to extend its configuration. Instructions are provided in the documentation [in this link](https://github.com/usabilla/php-docker-template#php-configuration).
