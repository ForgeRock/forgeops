# Docker Images for the ForgeRock Identity Platform

This directory contains Dockerfiles for building and deploying the ForgeRock 
Identity Platform. It includes Dockerfiles that are specific to a release (under
`7.0`), and Dockerfiles that are common across releases.

The Dockerfiles do not contain the configuration files needed to run the 
platform. The `bin/config.sh` script must be used to initialize the 
configuration. For more information, see the 
[CDK documentation](https://ea.forgerock.com/docs/forgeops/cdk/develop/intro.html).

## Dockerfiles for Release 7.x

For 7.x releases of the ForgeRock Identity Platform, the base Dockerfiles for 
AM, IDM, DS and IG are built upstream in their product repositories. These 
images are built and pushed to the `gcr.io/forgerock-io/` registry. The source 
for the Dockerfiles is maintained in the respective product source code 
repository. In general, these base images have the product binary laid down and 
are "ready to run", but do not contain any configuration.

The Dockerfiles in the [docker](./) directory are the "child" images that 
derive from the base images, and overlay any of your customizations and 
configuration files. These Docker images are built by Skaffold and pushed to 
your Kubernetes cluster.

## Dockerfiles Used for Multiple Releases

* `java-11`: The foundational Java 11 image used to build ForgeRock DS, IDM and 
  IG.
* `cli-tools`: Deployment and release management tooling.
* `gatling`: Gatling image used to benchmark and exercise the platform.

 ## See Also

* [Top-level forgeops README.md](../README.md)
* [Directory Server image customization](7.0/ds/README-DS.md)