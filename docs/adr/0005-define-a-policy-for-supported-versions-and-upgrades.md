# 5. Define a policy for supported versions and upgrades

Date: 2021-01-25

## Status

Accepted

## Context

Doubts have appeared as we decide which versions to drop from our pipeline and upgrade internal dependencies. In order to solve this we decided to be explicit with users on how we make those decisions.

## Decision

We have defined the following policy, to be mirrored in the README.

- We will provide continuous new builds for images while their versions are actively supported.
    - PHP versions will be supported until no longer in [Security Support](https://php.net/supported-versions.php).
    - alpine versions will be supported until they reach [EOL](https://alpinelinux.org/releases).
    - nginx versions will be supported until they are classified as [legacy](https://nginx.org/en/download.html).
- Past images will remain hosted on DockerHub as long as possible.
    - Once DockerHub limits are reached, images will become unavailable chronologically, unless they are still actively receiving new builds.
- Packages focused on development will only be enabled in the `dev` image, and be updated in reasonable timeframes.,
    - For example, Xdebug will only be shipped on `dev` versions and will be updated to the latest version as fast as possible.

## Consequences

This policy will guide our pipelines and is subject to changes depending on future changes in Github and DockerHub.
