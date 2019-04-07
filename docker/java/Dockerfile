# Base Java Image for ForgeRock Identity Platform. Used for DS, amster, IGx and IDM (Anything that does not need a web
# container)
#
# Copyright 2016-2019 ForgeRock AS. All Rights Reserved
#
# Use of this code requires a commercial software license with ForgeRock AS.
# or with one of its affiliates. All use shall be exclusively subject
# to such license between the licensee and ForgeRock AS.
#
FROM openjdk:11-jdk-slim
RUN jlink --compress=2 \
          --no-header-files \
          --no-man-pages \
          --strip-debug \
          --add-modules java.base,java.compiler,java.desktop,java.instrument,java.management.rmi,java.prefs,java.security.jgss,\
java.security.sasl,java.sql,jdk.security.auth,jdk.unsupported,java.datatransfer,java.logging,java.naming,java.rmi,java.scripting,\
java.sql.rowset,java.transaction.xa,java.xml,java.xml.crypto,jdk.xml.dom\
          --output /opt/jdk \
   && apt-get update && apt-get install -y binutils \
   && strip -p --strip-unneeded /opt/jdk/lib/server/libjvm.so 


FROM debian:stable-slim

COPY --from=0 /opt/jdk /opt/jdk

RUN adduser --home "/home/forgerock" -uid 11111 --gid 0 forgerock --disabled-password --gecos "forgerock user"

ENV JAVA_HOME /opt/jdk

ENV PATH $PATH:/opt/jdk/bin

