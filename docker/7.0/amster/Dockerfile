FROM gcr.io/forgerock-io/amster/pit1:7.0.0-a830bcb2ce3fa2ef4f01670d0dd92a221a7eaa9f

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
