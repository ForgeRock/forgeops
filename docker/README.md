# Docker Build Files for ForgeRock Identity Platform

## About

You will need to modify the Dockerfiles here to suit your needs. The Dockerfiles
are changing often as we find better ways to build these images for a wide range
 of requirements. 

## Binary Downloads

The forgerock/downloader docker image downloads artifacts from the ForgeRock maven repository. This downloader image
is the first stage in a multistage build process. The downloader image is unique to each user as it embeds 
the API_KEY needed to pull images from ForgeRock's Artifactory reposistory.  

IMPORTANT: *YOU MUST BUILD THIS IMAGE FOR YOUR OWN ENVIRONMENT!!*

To build this image you need a API Key for the maven repository.

ForgeRock customers should follow the backstage procedure for maven access.  

Internal users can obtain their API keys as follows:

* Navigate to http://docker-public.forgerock.io/repo/webapp/#/profile
* Log in. The User Profile page should appear.
* Re-enter your password in the Current Password field and click Unlock.
* Click Show API Key (the "eye" icon to the right of the API Key field).
* Copy your API Key.

Export an environment variable API_KEY=your_api_key before attempting to build Docker images using the downloader. For more information, see the  downloader/download script.

See the downloader-sample/ for an alternative way of sourcing ForgeRock binaries. 


## How to Run These Images

These images are intended to be
orchestrated using Kubernetes. They depend on external volumes being
mounted for secrets, configuration and persistent data. As such, they are not supported in non Kubernetes environments (docker compose, docker swarm, etc.)


## Image Builds

The product images are built automatically (using Conatainer Builder) when a commit is made to ForgeOps. These images are pushed to https://bintray.com/forgerock.


The java and git images are also available on the docker hub. They are built when a new commit is made to ForgeOps.

## build.sh

The `build.sh` script can be used for one-off builds during development. For example:

```
./build.sh openam 
```
Will build openam using the default tag and registry. 

## CSV Format

build.sh can also use a CSV file to determine which images to build and how to tag those images. For example:

```build.sh -C csv/dev.csv -a -p -d``` 

Will authenticate (-a option) to the docker registry, build, tag and push (-p option) all images found in dev.csv. The -d option is a "dry-run" which will show you the commands to be executed but will not peform any builds.

The CSV option is  intended for automating the build process. 

The CSV input file is parsed by bash, and is is *very* finicky about formatting. There are no comments allowed, no extra spaces after
commas, and the file must end in a newline. 

The format of the CSV file is:

```csv
folder,artifact,tag1,tag2

```

Where:

* folder - is the name of the docker/ folder to build
* artifact - is the version of the artifact in Artifactory. For example, for openam - 6.5.1-p2
* tags - zero or more tags to apply to the image. The artifact version will always be applied as a tag. You only need to pass in additional tags.


 See the build.sh script for a complete list of options.

## Process to update a dependency

The file csv/dev.csv specifies the artifacts used in our CI Cloudbuild pipeline. To update to a new milestone, edit
this file, and update the milestone (for example, for idm change 6.5.0-M2 to 6.5.0-M3). Commit the change, and submit a new PR. The build process will build and tag the new image.
