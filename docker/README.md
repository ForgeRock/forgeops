# Docker Images for the Ping Identity Platform

This directory contains Dockerfiles for building and deploying the Ping Identity Platform.

## Dockerfiles

The base Dockerfiles for PingAM, PingIDM, PingDS and PingGateway are built upstream in their product 
repositories. These images are scanned, built and pushed to the `us-docker.pkg.dev/forgeops-public/images-base` 
registry. The source for the Dockerfiles is maintained in the respective product source code repository. 

The Dockerfiles in the [docker](./) directory are the "child" images that 
derive from the base images, and overlay any of your customizations and 
configuration files. 

## Dockerfiles Used for Multiple Releases

* `gatling`: Gatling image used to benchmark and exercise the platform.

 ## See Also

* [Top-level forgeops README.md](../README.md)
* [PingDS server image customization](ds/README.md)
* [Alpine PingDS child image](../docker-alpine/ds/README.md) — the Alpine
  two-step: same shape as `docker/ds`, deriving from the DS team's Alpine
  base (tag dimension on `images-base/ds`) and re-applying the ForgeOps
  skeleton the upstream image does not carry.