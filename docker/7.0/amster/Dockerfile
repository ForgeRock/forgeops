FROM gcr.io/forgerock-io/amster/pit1:7.0.0-1ba22f76c82c315fb49843daf750f8aaadc971d5

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
