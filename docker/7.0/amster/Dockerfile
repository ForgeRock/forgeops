FROM gcr.io/forgerock-io/amster/pit1:7.0.0-3f3cc4dc08220dcf75986323b840c59366673229

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
