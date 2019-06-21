# Docker Images

## Utility Docker Images

* The `java` image is the foundational docker image for ForgeRock DS, IDM and IG.
* The `util` image is used in init containers to check for DS status. This will be deprecated in 
* `git` is used to git clone configuration at runtime. It will be deprecated in the future.


## Product docker images

For the 7.x release, the base product docker images for ForgeRock AM, IDM, DS and IG are built upstream
and hosted on gcr.io/forgerock-io/.  The source for the dockerfiles can be 
found in the respective product source code repository.


## Building Custom Images using skaffold 

The remaining images in this folder are used to build your custom docker images for deployment.

See the [EA Docs](https://ea.forgerock.com/docs/platform/devops-guide-minikube/index.html#devops-implementation-env-about-the-env)