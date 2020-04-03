FROM gcr.io/forgerock-io/amster/pit1:7.0.0-cdb190346f7b42b92925f2e4b5409a6c614f7355

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
