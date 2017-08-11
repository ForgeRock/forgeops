# Base Java Image for ForgeRock platform. Used for DJ, amster, IG and IDM (Anything that does not need a web
# container)
#
#
# Copyright (c) 2016-2017 ForgeRock AS.

FROM openjdk:8u131-jre-alpine

ENV FORGEROCK_HOME /opt/forgerock

# Install a number of utilities. Not all containers will need all of these - but these are quite small in size.
# git - formely used by amster
# openssh-client - needed by git for ssh:// repo access
# openldap-clients -used as a light weight ldap probe (C based- very small runtime and fast startup)
# bind-tools for dig (dns diagnostics)
# iputils - ping command
# libc6-compat - needed by OrientDB for IDM. Remove this once orient is deprecated in 5.5.
RUN apk add --no-cache su-exec unzip curl bash openldap-clients bind-tools iputils libc6-compat git openssh-client  \
    && mkdir -p /opt/forgerock \
    && addgroup -g 11111 forgerock \
    && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D -G forgerock forgerock \
    && chown -R forgerock /opt


