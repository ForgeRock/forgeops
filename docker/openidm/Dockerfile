#
# Copyright (c) 2016-2017 ForgeRock AS.
#FROM openjdk:8-jre
FROM openjdk:8-jre-alpine

WORKDIR /opt

EXPOSE 8080

ADD Dockerfile /

# Override these to change the JVM:
ENV JAVA_OPTS -Xmx1024m -server -XX:+UseG1GC

# This is only used if a git clone of an ssh: repo is performed.
ENV GIT_SSH_COMMAND ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh


# Download or add OpenIDM nightly build and unzip.
ADD openidm.zip /var/tmp/openidm.zip

# libc6-compat is needed by OrientDB as it uses the snappy Java shared library.
# postgresql-client is for debugging purposes - it can be removed if you wish.

RUN apk add --no-cache su-exec libc6-compat postgresql-client git openssh-client bash && \
   adduser -D -h  /opt/openidm openidm openidm && \
   unzip -q /var/tmp/openidm.zip && \
   chown -R openidm:openidm /opt/openidm && \
   rm -f /var/tmp/openidm.zip  && rm -fr /opt/openidm/samples &&
   git config --global user.email "auto-sync@forgerock.net" && \
   git config --global user.name "Git Auto-sync user"

ADD *.sh /opt/openidm/
ADD logging.properties /opt/openidm/logging.properties

WORKDIR /opt/openidm

ENTRYPOINT ["/opt/openidm/docker-entrypoint.sh"]

CMD ["openidm"]
