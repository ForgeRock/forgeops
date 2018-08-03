# Docker Build Files for ForgeRock Identity Platform

## About

You will need to modify the Dockerfiles here to suit your needs. The Dockerfiles
are changing often as we find better ways to build these images for a wide range
 of requirements. 

## Binary Downloads

The forgerock/downloader docker image downloads artifacts from the ForgeRock maven repository. This docker image
is the first stage in a multistage build. In order to build this image you need a API Key for the maven repository.

ForgeRock customers should follow the backstage procedure for maven access.  

Internal users can obtain their API keys as follows:

* Navigate to http://docker-public.forgerock.io/repo/webapp/#/profile
* Log in. The User Profile page should appear.
* Re-enter your password in the Current Password field and click Unlock.
* Click Show API Key (the "eye" icon to the right of the API Key field).
* Copy your API Key.

Export an environment variable API_KEY=your_api_key before attempting to build Docker images using the downloader. For more information, see the  downloader/download script.


## How to Run These Images

These images are intended to be
orchestrated using Kubernetes. They depend on external volumes being
mounted for secrets, configuration and persistent data. As such, they are not supported in non Kubernetes environments (docker compose, docker swarm, etc.)


## Image Builds

The product images are built automatically (using Conatainer Builder) when a commit is made to ForgeOps. These images are pushed to https://bintray.com/forgerock.


The java and git images are available on the docker hub. They are built when a new commit is made to ForgeOps
