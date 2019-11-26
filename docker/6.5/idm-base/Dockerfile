#
# Copyright (c) 2016-2019 ForgeRock AS.
FROM krallin/ubuntu-tini:bionic as download_tini

FROM tomcat:9-jdk8-adoptopenjdk-hotspot as unpack
RUN apt-get update && apt-get install -y unzip && apt-get clean all
COPY openidm.zip /openidm.zip
RUN mkdir -p /var/tmp/openidm && unzip -q /openidm.zip -d /var/tmp && rm -fr /var/tmp/openidm/samples


FROM tomcat:9-jdk8-adoptopenjdk-hotspot
ENV FORGEROCK_HOME /opt/forgerock

#RUN apk add --no-cache su-exec unzip curl bash bind-tools iputils sysstat tini \
#    && apk del --no-cache bind \
#    && mkdir -p "${FORGEROCK_HOME}" \
#    && addgroup -g 11111 forgerock \
#    && adduser -s /bin/bash -h  "${FORGEROCK_HOME}" -u 11111 -D -G root forgerock \
#    && chown -R forgerock:root /opt \
#    && chmod -R 0770 "${FORGEROCK_HOME}" \
#    && find / -perm +6000 -type f -exec chmod a-s {} \; || true

RUN apt-get update && apt-get install -y zip unzip curl bash wget dnsutils sysstat ldap-utils ttf-dejavu\
    && apt-get clean all \
    && addgroup --gid 11111 forgerock \
    && adduser --shell /bin/bash --home "$FORGEROCK_HOME" --uid 11111 --ingroup root  --disabled-password --gecos "" -q forgerock \
    && mkdir -p "$FORGEROCK_HOME" \
    && chown -R forgerock:root /opt \
    && chmod -R 0770 "${FORGEROCK_HOME}" \
    && find / -perm 6000 -type f -exec chmod a-s {} \; || true 

COPY --from=download_tini /usr/bin/tini /usr/bin/tini
COPY --from=download_tini /usr/bin/tini-static /usr/bin/tini-static

# This installs the GCP stack driver profiler. Adds approx 8MB
RUN mkdir -p /opt/cprof && \
     wget -q -O- https://storage.googleapis.com/cloud-profiler/java/latest/profiler_java_agent.tar.gz \
     | tar xzv -C /opt/cprof

# Installs the async-profiler - adds 280K
RUN mkdir -p /opt/async-profiler && \
    wget -q -O-  https://github.com/jvm-profiling-tools/async-profiler/releases/download/v1.5/async-profiler-1.5-linux-x64.tar.gz \
    | tar xzv -C /opt/async-profiler


# Copy IDM files
COPY --from=unpack /var/tmp/openidm /opt/openidm
RUN chown -R forgerock:root /opt/openidm 

#WORKDIR /opt

# Override these to change the JVM:
ENV JAVA_OPTS -Xmx1024m -server -XX:+UseG1GC -XX:+IgnoreUnrecognizedVMOptions --add-opens=java.base/jdk.internal.loader=ALL-UNNAMED


# Use this for Java 8 u131 or later. This sets the size of the VM heap according to the container size.
#ENV JAVA_OPTS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

# For a Debian base image use the RUN stanza below.
#
# RUN apt-get update && apt-get install -y ldap-utils  bash  && \
#     unzip -q /var/tmp/openidm.zip && \
#     rm -f /var/tmp/openidm.zip  && rm -fr /opt/openidm/samples && \
#     git config --global user.email "auto-sync@forgerock.net" && \
#     git config --global user.name "Git Auto-sync user"
# ttf-dejavu  - needed for Activiti workflow.

#RUN apk update && \
#    apk upgrade && \
#    apk add zip ttf-dejavu tini && \
#    apk add --no-cache nss

#RUN chown -R forgerock:forgerock /opt/openidm  && rm -fr /opt/openidm/samples

COPY *.sh /opt/openidm/
COPY logging.properties /opt/openidm/logging.properties

WORKDIR /opt/openidm

# Must be numeric. This is the forgerock user id.
USER 11111

ENV GIT_SSH_COMMAND ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/id_rsa


ENTRYPOINT ["/opt/openidm/docker-entrypoint.sh"]

CMD ["openidm"]
