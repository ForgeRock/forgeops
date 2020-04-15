FROM gcr.io/forgerock-io/amster/pit1:7.0.0-c074b15c0afe2eb92e4b39930b451263cee2ee9b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
