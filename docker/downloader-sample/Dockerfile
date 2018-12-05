# This is a sample alternate downloader for fetching ForgeRock binaries
# The ../downloader/ image assumes that you have an Artifactory API_KEY for pulling binaries from ForgeRock.
# If you don't have an API_KEY, and just want to build using local copies of the binary, this sample
# shows one way to replace the downloader image. There are many alternate stragies you could use. For example,
# downloading from a gcs bucket. 
#
# Build it with:
# docker build -t forgerock/downloader downloader-sample
# Note the tag above is set to forgerock/downloader. The multi-stage build expects to pull this image.
# See the download script for more details.

FROM alpine:latest

RUN apk add --update \
        bash \
        curl \
    && rm -rf /var/cache/apk/* \
    && echo $API_KEY >/api_key

# Example - Copy your desired artifacts to this folder then add them to the image. Put them in the root to mimic the functionality 
# of the ../downloader image.
COPY openam.war /
# COPY openidm.zip /var/tmp
# COPY openig.war /var/tmp
# COPY opendj.zip /var/tmp

# See the download script - you will need to edit this to mimic the 
COPY download /usr/bin/

ENTRYPOINT [ "/usr/bin/download" ]