# Docker Images for the ForgeRock Platform

This directory contains Dockerfiles used to build and deploy the ForgeRock platform.

There are Dockerfiles that are specific to a release (under `7.0` )
as well as Dockerfiles that are common across releases.

It is important to understand that many of the Dockerfiles do not contain the required configuration files needed to run the platform. The `bin/config.sh` script must be used to initialize the configuration. See the top level [README](../README.md).

## Common Docker Images

* `java-11`: The foundational Java 11 image used to build ForgeRock DS, IDM and IG.
* `cli-tools`: Wraps up cluster provisiong tools in a container.
* `forgeops-secrets`: Docker image that generates random secrets for the platform.
* `gatling`: Gatling image used to benchmark and exercise the platform.


Dockerfiles that will soon be deprecated as they are no longer required by kustomize, include:

* `util`:  Used in init containers to check for DS status.
* `git`: Used to git clone configuration at runtime.

## Dockerfiles for Release 7.0

For the 7.x release, the base Dockerfiles for ForgeRock AM, IDM, DS and IG are built upstream in their respective product repositories. These images are built
and pushed  to `gcr.io/forgerock-io/`.  The source for the Dockerfiles can be
found in the respective product source code repository. In general, these base images have
the product binary laid down and are "ready to run", but do not contain any configuration.

The Dockerfiles in the [docker/7.0](7.0/) directory are the "child" images that derive from the base
image and overlay any of your customizations and configuration files. These Dockerfiles
are built by skaffold and pushed to your Kubernetes cluster.

## See Also

* [README.md](../README.md)
* [Directory Server Image customization](7.0/ds/README-DS.md)