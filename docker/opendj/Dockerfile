# OpenDJ Docker image
#
# Copyright (c) 2016-2017 ForgeRock AS.

#FROM openjdk:8-jre-alpine

FROM openjdk:8-jre

WORKDIR /opt

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Default options for a small instance. Overrride the environment var OPENDJ_JAVA_ARGS as needed
ENV OPENDJ_JAVA_ARGS -server -Xmx512m -XX:+UseG1GC


# Path to secret file that contains the cn=Directory Manager password
# Used to configure the image
# Mount a Docker volume or Kubernetes secret volume on /var/secrets/opendj
# This is the path to the password file
# If no volume is mounted, a default password is set
ENV DIR_MANAGER_PW_FILE /var/secrets/opendj/dirmanager.pw

ENV BASE_DN dc=example,dc=com

# Example of how you can download the DJ zip file from a maven repo
# ENV MVN_REPO=https://maven.forgerock.org/repo/repo/org/forgerock/opendj
# ENV OPENDJ_VERSION=4.0.0-SNAPSHOT
#RUN curl $MVN_REPO/opendj-server-legacy/$OPENDJ_VERSION/opendj-server-legacy-$OPENDJ_VERSION.zip -o /tmp/opendj.zip

# Use this to directly add the opendj zip file
ADD opendj.zip /tmp/


# Creating instance.loc consolidates the writable directories under one root
# We also create the extensions directory
# We set a dir manager default password value here, but this is almost
# certainly not what you want. This hard coded path to the password
# should get over mounted by a secret volume with the "real" password. See README.md

# If you want to use Alpine install this
#RUN apk add --no-cache su-exec openldap-clients && \

RUN apt-get update && apt-get install -y ldap-utils && \
    unzip -q /tmp/opendj.zip -d /opt  && rm /tmp/opendj.zip && \
    echo "/opt/opendj/data" > /opt/opendj/instance.loc  && \
    mkdir -p /opt/opendj/data/lib/extensions && \
    mkdir -p /var/secrets/opendj && \
    echo -n "password"  > ${DIR_MANAGER_PW_FILE}


WORKDIR /opt/opendj

ADD Dockerfile /
ADD bootstrap/ /opt/opendj/bootstrap/
ADD *.sh /opt/opendj/


EXPOSE 389 636 4444 8989

ADD run.sh /opt/opendj/run.sh


CMD ["/opt/opendj/run.sh"]
