# Docker Build Files for the ForgeRock Identity Platform

## Contributing 

To create a pull request, fork the project to your private community Bitbucket Server/Bitbucket 
Server account, clone it to your workstation, commit your changes, and push them
up to your Bitbucket Server repository. You can then create a pull request on 
Bitbucket.

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


# Building Minor or Patch Releases

If you want to use a major or minor release (AM 14.0.1, for example), log on to
backstage.forgerock.com and download the appropriate binary. The binary should be
placed in the Docker build directory (e.g. openam/) and should not have any
version info (openam.war, not OpenAM-14.0.1.war).

# Using a Private Docker Registry 

The maven pom.xml builds Docker images and optionally push them to a registry. Images are
available in ForgeRock's private registry server at docker-public.forgerock.io. This registry
is currently limited to ForgeRock staff. 

To access the registry you will need 
[ForgeRock backstage credentials](https://backstage.forgerock.com/login) and the appropriate permissions to pull images.  
You can browse the available images using [artifactory](https://docker-public.forgerock.io/repo/webapp/#/artifacts/browse/tree/General/docker-public) 

To use the registry you must authorize Docker to pull images:

```docker login -e your_email -u your_backstage_id  -p your_password docker-public.forgerock.io```

You can now pull and run images. For example:

```docker pull docker-public.forgerock.io/forgerock/openam:14.5.0-SNAPSHOT```

To use the private registry in Helm charts in a Kubernetes deployment, 
see the documentation [here](https://Bitbucket Server.forgerock.org/projects/DOCKER/repos/fretes/browse). 

# Kubernetes

If you are interested in running on a Kubernetes cluster, see the helm/ folder

# How to Run These Images

Please see the README.md in each directory. For the most part these images are intended to be
orchestrated together using something like Kubernetes. They depend on external volumes being
mounted for secrets, configuration and persistent data.
