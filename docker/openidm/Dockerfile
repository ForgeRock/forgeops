#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#FROM openjdk:8-jre
FROM openjdk:8-jre-alpine

WORKDIR /opt

EXPOSE 8080

ADD Dockerfile /

# Override these to change the JVM:
ENV JAVA_OPTS -Xmx1024m -server -XX:+UseG1GC

# Download or add OpenIDM nightly build and unzip.
ADD openidm.zip /var/tmp/openidm.zip

# libc6-compat is needed by OrientDB as it uses the snappy Java shared library.
# postgresql-client is for debugging purposes - it can be removed if you wish.

RUN apk add --no-cache su-exec libc6-compat postgresql-client && \
   adduser -D -h  /opt/openidm openidm openidm && \
   unzip -q /var/tmp/openidm.zip && \
   chown -R openidm:openidm /opt/openidm && \
   rm -f /var/tmp/openidm.zip  && rm -fr /opt/openidm/samples

ADD docker-entrypoint.sh /opt/openidm/docker-entrypoint.sh
ADD logging.properties /opt/openidm/logging.properties

WORKDIR /opt/openidm

ENTRYPOINT ["/opt/openidm/docker-entrypoint.sh"]

CMD ["openidm"]
