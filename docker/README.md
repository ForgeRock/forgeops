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
* Maven. Run  ``mvn`` to download the dependencies and build the Docker images.

Maven is the preferred builder for a CI such as Jenkins. There are two goals:
`docker:build` and  `docker:push`

The default goal is `docker:build`.

Note that Maven pulls artifacts from ForgeRock's Artifactory server. You need
your backstage credentials in your ~/.m2/settings.xml file to authenticate to the server.  

You can obtain credentials using this trick:
```
curl -u your.backstage.login -O "http://maven.forgerock.org/repo/internal/settings.xml" 
```
Note that access to the Artifactory server is restricted to ForgeRock staff, partners and subscription customers.


## Building Minor or Patch Releases

If you want to use a major or minor release (AM 14.0.1, for example), log on to
backstage.forgerock.com and download the appropriate binary. The binary should be
placed in the Docker build directory (e.g. openam/) and should not have any
version info (openam.war, not OpenAM-14.0.1.war).

## Kubernetes

If you are interested in running on a Kubernetes cluster, see the helm/ folder

## How to Run These Images

Please see the README.md in each directory. These images are intended to be
orchestrated together using Kubernetes. They depend on external volumes being
mounted for secrets, configuration and persistent data. As such, they are not supported in non Kubernetes environments (docker compose, docker swarm, etc.)


## Image Builds

The product images are built automatically (using Conatainer Builder) when a commit is made to ForgeOps. These images are pushed to https://bintray.com/forgerock.


The java and git images are available on the docker hub. They are built when a new commit is made to ForgeOps
