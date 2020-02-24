FROM gcr.io/forgerock-io/amster/pit1:7.0.0-9e1bfc2775f81ae2bea36cae67cc00e82c816424

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
