FROM gcr.io/forgerock-io/amster:7.0.0-83fd33b8e91b02e2f3ce0c47c5c5fef6b5be40d2

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
