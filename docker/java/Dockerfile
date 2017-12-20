# Base Java Image for ForgeRock Identity Platform. Used for DJ, amster, IG and IDM (Anything that does not need a web
# container)
#
#
# Copyright (c) 2016-2017 ForgeRock AS.

FROM openjdk:8u151-jre-alpine

ENV FORGEROCK_HOME /opt/forgerock

# Install a number of utilities. Not all containers will need all of these - but these are quite small in size.
# git - formely used by amster
# bind-tools for dig (dns diagnostics)
# iputils - ping command
# CDIC-72 - find / -perm +6000 -type f -exec chmod a-s {} \; || true
RUN apk add --no-cache su-exec unzip curl bash bind-tools iputils \
    && apk del --no-cache bind \
    && mkdir -p "${FORGEROCK_HOME}" \
    && addgroup -g 11111 forgerock \
    && adduser -s /bin/bash -h  "${FORGEROCK_HOME}" -u 11111 -D -G forgerock forgerock \
    && chown -R forgerock /opt \
    && chmod -R 0750 "${FORGEROCK_HOME}" \
    && find / -perm +6000 -type f -exec chmod a-s {} \; || true


