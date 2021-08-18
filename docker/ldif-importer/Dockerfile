# FROM gcr.io/forgerock-io/ds/pit1:7.0.0-ldif-importer
# Temporary fix for debian build issue
FROM gcr.io/forgerock-io/ds/docker-build:7.2.0-f114c6bd95760f7f5c53ebb0d3d4f08f117d592d

USER 0

COPY debian-buster-sources.list /etc/apt/sources.list

RUN apt-get update -y && apt-get install -y curl

USER 11111

COPY --chown=forgerock:root start.sh /opt/opendj
COPY --chown=forgerock:root ds-passwords.sh /opt/opendj

ENTRYPOINT /opt/opendj/start.sh
