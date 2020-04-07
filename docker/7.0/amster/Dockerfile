FROM gcr.io/forgerock-io/amster/pit1:7.0.0-5ccd5f7029e6f52f4874bd86f09a5f7b671635e5

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
