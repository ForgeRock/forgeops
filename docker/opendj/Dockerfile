# OpenDJ Docker image
#
# Copyright (c) 2016-2017 ForgeRock AS.

FROM forgerock/java:5.5.0

WORKDIR /opt

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Default options for a small instance. Overrride the environment var OPENDJ_JAVA_ARGS as needed
#ENV OPENDJ_JAVA_ARGS -server -Xmx512m -XX:+UseG1GC
# You can use these options on jdk 8u131 or later. This will set the heap size according to the container size
ENV OPENDJ_JAVA_ARGS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

ENV SECRET_PATH /var/run/secrets/opendj

# Path to secret file that contains the cn=Directory Manager password
# Used to configure the image
# Mount a Docker volume or Kubernetes secret volume on /var/run/secrets/opendj
# If no volume is mounted, a default password is used.
ENV DIR_MANAGER_PW_FILE /var/run/secrets/opendj/dirmanager.pw

# The default BASE_DN of the directory tree.
ENV BASE_DN dc=openam,dc=forgerock,dc=org

# The default backup directory. Only relevant if backups have been scheduled.
ENV BACKUP_DIRECTORY /opt/opendj/backup

# Optional full backup schedule in cron (5) format.
ENV BACKUP_SCHEDULE_FULL  "0 2 * * *"

# Optional incremental backup schedule in cron(5) format.
ENV BACKUP_SCHEDULE_INCREMENTAL "15 * * * *"

# The hostname to run the backups on. If this hostname does not match the container hostname, the backups will *not* be scheduled.
# The default value below means backups will not be scheduled automatically. Set this environment variable if you want backups.
ENV BACKUP_HOST dont-run-backups

# Example of how you can download the DJ zip file from a maven repo
# ENV MVN_REPO=https://maven.forgerock.org/repo/repo/org/forgerock/opendj
# ENV OPENDJ_VERSION=4.0.0-SNAPSHOT
#RUN curl $MVN_REPO/opendj-server-legacy/$OPENDJ_VERSION/opendj-server-legacy-$OPENDJ_VERSION.zip -o /tmp/opendj.zip

# Use this to directly add the opendj zip file
ADD opendj.zip /home/forgerock/


ENV INSTANCE_ROOT /opt/opendj/data

RUN unzip -q /home/forgerock/opendj.zip -d /opt \
    && rm -f /home/forgerock/opendj.zip \
    && mkdir -p "$INSTANCE_ROOT" \
    && mkdir -p "$SECRET_PATH" \
    && chown -R forgerock /opt "$SECRET_PATH"


ADD bootstrap/ /opt/opendj/bootstrap/
ADD *.sh /opt/opendj/


#
#    mkdir -p /opt/opendj/data/lib/extensions && \
#     echo -n "password"  > ${DIR_MANAGER_PW_FILE}

# Note the following RUN command has been removed for DJ 4.1.0.
# 4.1.0 uses --instancePath instead of instance.loc on setup.sh and set INSTANCE_ROOT on boot.
#     echo "/opt/opendj/data" > /opt/opendj/instance.loc  && \

WORKDIR /opt/opendj

USER forgerock

EXPOSE 1389 636 4444 8989


CMD ["/opt/opendj/run.sh"]
