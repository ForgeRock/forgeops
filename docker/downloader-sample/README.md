# Downloader sample

This demonstrates an alternate docker downloader that can replace the functionality of the ../downloader image.

Manually place your artifacts (openam.war, opendj.zip, openig.war, openidm.zip) into
this folder, edit the Dockerfile, and build and tag this image:

`docker build -t forgerock/downloader .`

Note the image should be named "forgeock/downloader" - as it is intended to replace the functionality of the ../downloader image.
This image will be called as the first stage of a multi-stage build.

