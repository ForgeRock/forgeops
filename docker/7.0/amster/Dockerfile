FROM gcr.io/forgerock-io/amster/pit1:7.0.0-fdb09b62d06c7d9825a2c6a398aed4fcd4d74298

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
