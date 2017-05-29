# OpenDJ Docker image
#
# Copyright (c) 2016-2017 ForgeRock AS.

#FROM openjdk:8-jre-alpine

FROM openjdk:8u131-jre

WORKDIR /opt

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Default options for a small instance. Overrride the environment var OPENDJ_JAVA_ARGS as needed
#ENV OPENDJ_JAVA_ARGS -server -Xmx512m -XX:+UseG1GC
# You can use these options on jdk 8u131 or later. This will set the heap size according to the container size
ENV OPENDJ_JAVA_ARGS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

# Path to secret file that contains the cn=Directory Manager password
# Used to configure the image
# Mount a Docker volume or Kubernetes secret volume on /var/secrets/opendj
# If no volume is mounted, a default password is used.
ENV DIR_MANAGER_PW_FILE /var/secrets/opendj/dirmanager.pw

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
ADD opendj.zip /tmp/

# We set a dir manager default password value here, but this is almost
# certainly not what you want. This hard coded path to the password
# should get over mounted by a secret volume with the "real" password. See README.md

# If you want to use Alpine install this
#RUN apk add --no-cache su-exec openldap-clients && \


RUN apt-get update && apt-get install -y ldap-utils && \
    unzip -q /tmp/opendj.zip -d /opt  && rm /tmp/opendj.zip && \
    mkdir -p /opt/opendj/data/lib/extensions && \
    mkdir -p /var/secrets/opendj && \
    echo -n "password"  > ${DIR_MANAGER_PW_FILE}

# Note the following RUN command has been removed for DJ 4.1.0.
# 4.1.0 uses --instancePath instead of instance.loc on setup.sh and set INSTANCE_ROOT on boot.
#     echo "/opt/opendj/data" > /opt/opendj/instance.loc  && \
ENV INSTANCE_ROOT /opt/opendj/data

WORKDIR /opt/opendj

ADD Dockerfile /
ADD bootstrap/ /opt/opendj/bootstrap/
ADD *.sh /opt/opendj/


EXPOSE 389 636 4444 8989

ADD run.sh /opt/opendj/run.sh


CMD ["/opt/opendj/run.sh"]
