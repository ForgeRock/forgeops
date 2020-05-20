FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8d5f71604c2c454a3ab73606b6f8558159c8bc17

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
