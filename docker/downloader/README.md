# Forgerock Downloader

The purpose of this image is to download the ForgeRock platform binaries that are used to build the various docker images.

This image *must* be built and tagged as `forgerock/downloader:latest`.  It is used as the first stage of a multi-stage build
in order to fetch the platform binaries.

To build this image you must have an API_KEY that has permission to pull from the ForgeRock bintray repository. See ../README.md for further information.

The build.sh script will attempt to build this image if it is not found in your docker cache.


The protocol that this image follows is to download the specified version of the artifact, and leave it in the root directory with a non versioned name.

For example:

```
FROM forgerock/downloader 

ARG VERSION="6.5.0"
RUN download -v $VERSION opendj
```

Will download RC4 of the directory server, and leave it in the root folder named opendj.zip. Subsequent stages in the docker build will copy this file from the root directory for installation in the final docker image.

See ../downloader-sample for an alternate approach.
