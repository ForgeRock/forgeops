FROM gcr.io/forgerock-io/amster/pit1:7.0.0-945dce6641c8defab26fee9354c440062e6e9a86

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
