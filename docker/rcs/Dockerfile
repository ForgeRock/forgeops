# 1. Accept build arguments in the FROM instruction.
# @example

ARG REPO=gcr.io/forgerock-io/rcs
ARG TAG=1.5.20.35

FROM ${REPO}:${TAG} AS source
 
# Merge your custom files with the RCS installation.
# @example
# COPY openicf/conf conf
# COPY openicf/connectors connectors
# COPY openicf/lib lib
# COPY openicf/scripts scripts

FROM amazoncorretto:26-alpine3.23-jdk AS release

COPY --from=source /opt/openicf /opt/openicf

WORKDIR /opt/openicf
COPY docker-entrypoint.sh bin/docker-entrypoint.sh

RUN apk -U upgrade

USER 11111
