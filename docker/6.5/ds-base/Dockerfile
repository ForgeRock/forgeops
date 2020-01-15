#
# Copyright (c) 2016-2019 ForgeRock AS.

FROM krallin/ubuntu-tini:bionic as download_tini


FROM adoptopenjdk/openjdk8:debian-slim as unpack
RUN apt-get update && apt-get install -y unzip && apt-get clean all
COPY opendj.zip /var/tmp/opendj.zip
WORKDIR /var/tmp/bootstrap
COPY bootstrap/ /var/tmp/bootstrap/
# This speeds up docker cloudbuild considerably
ENV OPENDJ_JAVA_ARGS "-Djava.security.egd=file:/dev/./urandom"
RUN ./setup.sh


FROM adoptopenjdk/openjdk8:debian-slim
RUN apt-get update && apt-get install -y curl wget fio dumb-init \
    && apt-get clean all \
    && addgroup --gid 11111 forgerock \
    && adduser --shell /bin/bash --home /opt/opendj --uid 11111 --ingroup root  --disabled-password --gecos "" -q forgerock

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

COPY --from=unpack /var/tmp/bootstrap/run/dsrs1 /opt/opendj/
WORKDIR /opt/opendj

# This is the default location where secrets should be mounted.
ENV SECRET_PATH /var/run/secrets/opendj
# Path to secret file that contains the cn=Directory Manager password
# Used to configure the image
ENV DIR_MANAGER_PW_FILE /var/run/secrets/opendj/dirmanager.pw

# Path to the file that contains the uid=monitor user password for Prometheus metrics.
ENV MONITOR_PW_FILE /var/run/secrets/opendj/monitor.pw
# Paths to the keystore and the keystore pin.
ENV KEYSTORE_FILE /var/run/secrets/opendj/keystore.pkcs12
ENV KEYSTORE_PIN_FILE /var/run/secrets/opendj/keystore.pin
# Default Java arguments - may be overridden when deployed
# Scale to 75% of available memory
ENV OPENDJ_JAVA_ARGS "-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

COPY *.sh /opt/opendj/
COPY bootstrap/secrets/* /var/run/secrets/opendj/
COPY scripts/ /opt/opendj/scripts/

RUN chown -R forgerock:root /opt/opendj

USER 11111

ENV PATH $PATH:/opt/opendj/scripts:/opt/opendj/bin


ENTRYPOINT  ["/opt/opendj/docker-entrypoint.sh"]

CMD ["start"]



