# Base Java Image for ForgeRock Identity Platform. Used for DS, amster, IGx and IDM (Anything that does not need a web
# container)
#
#
# Copyright (c) 2016-2019 ForgeRock AS.
FROM openjdk:11-jdk
RUN jlink --compress=2 \
          --no-header-files \
          --no-man-pages \
          --strip-debug \
          --add-modules java.base,java.compiler,java.desktop,java.instrument,java.management.rmi,java.prefs,java.security.jgss,java.security.sasl,java.sql,jdk.security.auth,jdk.unsupported \
          --output /opt/jdk \
   && apt-get update && apt-get install -y binutils \
   && strip -p --strip-unneeded /opt/jdk/lib/server/libjvm.so 


FROM debian:sid-slim

COPY --from=0 /opt/jdk /opt/jdk

RUN adduser --home "/home/forgerock" -uid 11111 --gid 0 forgerock --disabled-password --gecos "forgerock user"

ENV JAVA_HOME /opt/jdk