FROM gcr.io/forgerock-io/ds:7.3.1

USER 0

COPY debian-buster-sources.list /etc/apt/sources.list

RUN apt-get update -y && apt-get install -y curl

USER 11111

COPY --chown=forgerock:root start.sh /opt/opendj
COPY --chown=forgerock:root ds-passwords.sh /opt/opendj

ENTRYPOINT /opt/opendj/start.sh
