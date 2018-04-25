# OpenDJ Docker image
#
# Copyright (c) 2016-2017 ForgeRock AS.

# The java docker image source can be found at https://github.com/ForgeRock/docker-public
FROM forgerock/java:6.0.0

WORKDIR /opt

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Default options for a small instance. Overrride the environment var OPENDJ_JAVA_ARGS as needed
#ENV OPENDJ_JAVA_ARGS -server -Xmx512m -XX:+UseG1GC
# You can use these options on jdk 8u131 or later. This will set the heap size according to the container size
ENV OPENDJ_JAVA_ARGS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+UseCompressedOops

######## Secret Paths ########

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

ENV SSL_CERT_ALIAS opendj-ssl


# The default BASE_DN of the directory tree.
ENV BASE_DN o=userstore

# Optional full backup schedule in cron (5) format.
ENV BACKUP_SCHEDULE_FULL  "0 2 * * *"

# Optional incremental backup schedule in cron(5) format.
ENV BACKUP_SCHEDULE_INCREMENTAL "15 * * * *"


# Example of how you can download the DJ zip file from a maven repo
# ENV MVN_REPO=https://maven.forgerock.org/repo/repo/org/forgerock/opendj
# ENV OPENDJ_VERSION=4.0.0-SNAPSHOT
#RUN curl $MVN_REPO/opendj-server-legacy/$OPENDJ_VERSION/opendj-server-legacy-$OPENDJ_VERSION.zip -o /tmp/opendj.zip

# Use this to directly add the opendj zip file
COPY opendj.zip /home/forgerock/

RUN unzip -q /home/forgerock/opendj.zip -d /opt \
    && chown -R forgerock:root /opt \
    && chmod g+rwx /opt/opendj \
    && rm -f /home/forgerock/opendj.zip


COPY bootstrap/ /opt/opendj/bootstrap/
COPY scripts/ /opt/opendj/scripts/
COPY secrets/ /opt/opendj/secrets/
COPY *.sh /opt/opendj/

RUN chown -R forgerock:root /opt/opendj \
    && chmod g+rwx /opt/opendj

WORKDIR /opt/opendj

# In the past we ran into https://github.com/kubernetes/kubernetes/issues/2630
# Adding the forgerock user (11111) to the root group has solved the issue. This is the approach openshift uses.
USER 11111

EXPOSE 1389 636 4444 8989

ENTRYPOINT  ["/opt/opendj/docker-entrypoint.sh"]
CMD ["run"]
