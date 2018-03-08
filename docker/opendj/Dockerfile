# OpenDJ Docker image
#
# Copyright (c) 2016-2017 ForgeRock AS.

# The java docker image source can be found at https://github.com/ForgeRock/docker-public
FROM quay.io/forgerock/java:6.0.0

WORKDIR /opt

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Default options for a small instance. Overrride the environment var OPENDJ_JAVA_ARGS as needed
#ENV OPENDJ_JAVA_ARGS -server -Xmx512m -XX:+UseG1GC
# You can use these options on jdk 8u131 or later. This will set the heap size according to the container size
ENV OPENDJ_JAVA_ARGS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+UseCompressedOops
ENV SECRET_PATH /var/run/secrets/opendj

# Path to secret file that contains the cn=Directory Manager password
# Used to configure the image
# Mount a Docker volume or Kubernetes secret volume on /var/run/secrets/opendj
# If no volume is mounted, a default password is used.
ENV DIR_MANAGER_PW_FILE /var/run/secrets/opendj/dirmanager.pw

# The default BASE_DN of the directory tree.
ENV BASE_DN dc=openam,dc=forgerock,dc=org

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
    && rm -f /home/forgerock/opendj.zip \
    && mkdir -p "$SECRET_PATH" \
    && chown -R forgerock:root /opt "$SECRET_PATH" \
    && chmod g+rwx /opt/opendj


COPY bootstrap/ /opt/opendj/bootstrap/
COPY scripts/ /opt/opendj/scripts/
COPY *.sh /opt/opendj/


WORKDIR /opt/opendj

# We are hitting https://github.com/kubernetes/kubernetes/issues/2630
# We need to run as root. We can investigate using gosu to drop to the forgerock user at runtime.
USER 11111

EXPOSE 1389 636 4444 8989

ENTRYPOINT  ["/opt/opendj/docker-entrypoint.sh"]
CMD ["run"]
