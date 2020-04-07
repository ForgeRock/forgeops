FROM gcr.io/forgerock-io/amster/pit1:7.0.0-7e73dc9231eb0ef98a323c9c598fddb559fe8675

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
