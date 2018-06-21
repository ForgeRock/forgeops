#
# Copyright (c) 2016-2017 ForgeRock AS.

FROM forgerock/java:6.0.0

WORKDIR /opt

# Override these to change the JVM:
ENV JAVA_OPTS -Xmx1024m -server -XX:+UseG1GC
# Use this for Java 8 u131 or later. This sets the size of the VM heap according to the container size.
#ENV JAVA_OPTS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

# Download or add OpenIDM nightly build and unzip.
COPY openidm.zip /tmp/openidm.zip

# For a Debian base image use the RUN stanza below.
#
# RUN apt-get update && apt-get install -y ldap-utils  bash  && \
#     unzip -q /var/tmp/openidm.zip && \
#     rm -f /var/tmp/openidm.zip  && rm -fr /opt/openidm/samples && \
#     git config --global user.email "auto-sync@forgerock.net" && \
#     git config --global user.name "Git Auto-sync user"
# ttf-dejavu  - needed for Activiti workflow.

RUN apk update && \
    apk upgrade && \
    apk add zip ttf-dejavu tini

RUN unzip -q /tmp/openidm.zip && \
    chown -R forgerock:forgerock /opt/openidm && \
    rm -f /tmp/openidm.zip  && rm -fr /opt/openidm/samples

COPY *.sh /opt/openidm/
COPY logging.properties /opt/openidm/logging.properties

WORKDIR /opt/openidm

# Must be numeric. This is the forgerock user id.
USER 11111

ENV GIT_SSH_COMMAND ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/id_rsa


ENTRYPOINT ["/opt/openidm/docker-entrypoint.sh"]

CMD ["openidm"]
