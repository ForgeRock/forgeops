FROM gcr.io/forgerock-io/amster/pit1:7.0.0-b810b2527e2c13b71f62f0f7f3205cad3d6ad032

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
