FROM gcr.io/forgerock-io/amster/pit1:7.0.0-0092702a8d1e4fe6782f4716d751128f8d643412

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
