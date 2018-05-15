# Docker Build Files for ForgeRock Identity Platform

## About

You will need to modify the Dockerfiles here to suit your needs. The Dockerfiles
are changing often as we find better ways to build these images for a wide range
 of requirements. 

## Building

There are a few ways to build the Docker images:

* Manually. Copy the relevant artifacts (example: openam.war) to the directory
and run ```docker build -t forgerock/openam openam```.

* Use the build.sh shell script. This essentially the same as 
performing a manual build. The build.sh script
is available for convenience. 

## ForgeRock platform components

Yoy must log on to backstage to download the relevant ForgeRock products. The dl.sh script 
is provided as an example of how to automate this process. You must have an API_KEY to use this script.

## Building Minor or Patch Releases

If you want to use a major or minor release (AM 14.0.1, for example), log on to
backstage.forgerock.com and download the appropriate binary. The binary should be
placed in the Docker build directory (e.g. openam/) and should not have any
version info (openam.war, not OpenAM-14.0.1.war).

## How to Run These Images

These images are intended to be
orchestrated together using Kubernetes. They depend on external volumes being
mounted for secrets, configuration and persistent data. As such, they are not supported in non Kubernetes environments (docker compose, docker swarm, etc.)


## Image Builds

The product images are built automatically (using Conatainer Builder) when a commit is made to ForgeOps. These images are pushed to https://bintray.com/forgerock.


The java and git images are available on the docker hub. They are built when a new commit is made to ForgeOps
