# Base Tomcat Image for ForgeRock Identity Platform. Used for components that requires a web container (AM, IG)
#
# Copyright (c) 2016-2017 ForgeRock AS.

FROM tomcat:8.5-jre8-alpine

ENV FORGEROCK_HOME /opt/forgerock

ENV CATALINA_OPTS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap


# Install a number of utilities. Not all containers will need all of these - but these are quite small in size
# git - used by amster
# openssh-client - needed by git for ssh:// repo access
# openldap-clients -used as a light weight ldap probe (C based- very small runtime and fast startup)
# bind-tools for dig (dns diagnostics)
# iputils - ping command
RUN apk add --no-cache su-exec unzip curl bash openldap-clients bind-tools iputils \
    && rm -fr "$CATALINA_HOME"/webapps/* \
    && mkdir -p /opt/forgerock \
    && addgroup -g 11111 forgerock \
    && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D -G forgerock forgerock \
    && chown -R forgerock /opt
