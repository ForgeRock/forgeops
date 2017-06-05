#
# Copyright (c) 2016-2017 ForgeRock AS.
#FROM openjdk:8-jre
# Alpine
FROM openjdk:8u131-jre-alpine

WORKDIR /opt

EXPOSE 8080

ADD Dockerfile /

# Override these to change the JVM:
#ENV JAVA_OPTS -Xmx1024m -server -XX:+UseG1GC
# Use this for Java 8 u131 or later. This sets the size of the VM heap according to the container size.
ENV JAVA_OPTS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

# Download or add OpenIDM nightly build and unzip.
ADD openidm.zip /var/tmp/openidm.zip

# For a Debian base image use the RUN stanza below.
#
# RUN apt-get update && apt-get install -y ldap-utils  bash  && \
#     unzip -q /var/tmp/openidm.zip && \
#     rm -f /var/tmp/openidm.zip  && rm -fr /opt/openidm/samples && \
#     git config --global user.email "auto-sync@forgerock.net" && \
#     git config --global user.name "Git Auto-sync user"


# For alpine:
# libc6-compat is needed by OrientDB as it uses the snappy Java shared library.
# postgresql-client is for debugging purposes - it can be removed if you wish.
RUN apk add --no-cache su-exec bash libc6-compat curl && \
    adduser -D -h  /opt/openidm openidm openidm && \
    unzip -q /var/tmp/openidm.zip && \
    chown -R openidm:openidm /opt/openidm && \
    rm -f /var/tmp/openidm.zip  && rm -fr /opt/openidm/samples

ADD *.sh /opt/openidm/
ADD logging.properties /opt/openidm/logging.properties

WORKDIR /opt/openidm

ENTRYPOINT ["/opt/openidm/docker-entrypoint.sh"]

CMD ["openidm"]
