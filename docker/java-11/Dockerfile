# Base Java Image for ForgeRock Identity Platform. Used for DS, amster, IGx and IDM (Anything that does not need a web
# container)
#
# Copyright 2019 ForgeRock AS. All Rights Reserved
#
# Use of this code requires a commercial software license with ForgeRock AS.
# or with one of its affiliates. All use shall be exclusively subject
# to such license between the licensee and ForgeRock AS.
#
# Revist once https://github.com/docker-library/openjdk/issues/320 is resolved
#FROM openjdk:11-jdk-slim

FROM adoptopenjdk/openjdk11:debian-slim

# Adopt openjdk packaging appears to be different than the vanilla openjdk. The following 
# jlink command does not work on adoptopenjdk. We elect to use the full JDK instead.
# RUN jlink --compress=2 \
#           --no-header-files \
#           --no-man-pages \
#           --strip-debug \
#           --add-modules java.base,java.compiler,java.desktop,java.instrument,java.management.rmi,java.prefs,java.security.jgss,\
# java.security.sasl,java.sql,jdk.security.auth,jdk.unsupported,java.datatransfer,java.logging,java.naming,java.rmi,java.scripting,\
# java.sql.rowset,java.transaction.xa,java.xml,java.xml.crypto,jdk.xml.dom,\
# jdk.crypto.ec,jdk.crypto.cryptoki \
#           --output /opt/jdk \
#    && apt-get update && apt-get install -y binutils \
#    && strip -p --strip-unneeded /opt/jdk/lib/server/libjvm.so 

# The base image is from debian slim, so a multi-stage build does not makes sense. Revist 
# If we move back to the openjdk base.
# FROM debian:stable-slim
# COPY --from=0 /opt/jdk /opt/jdk

RUN adduser --home "/home/forgerock" -uid 11111 --gid 0 forgerock --disabled-password --gecos "forgerock user" 
