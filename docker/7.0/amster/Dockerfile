FROM gcr.io/forgerock-io/amster/pit1:7.0.0-96f306cd9ec7b39b43e23ecd67738ce57e57c6ff

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
