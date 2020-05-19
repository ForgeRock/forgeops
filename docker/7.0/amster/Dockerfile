FROM gcr.io/forgerock-io/amster/pit1:7.0.0-f2c6ed7e7cff48d00f079c59887e9bfe0c816517

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
