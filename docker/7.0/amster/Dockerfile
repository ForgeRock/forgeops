FROM gcr.io/forgerock-io/amster/pit1:7.0.0-93925e8690e48c87052eeca35a59538f104479a2

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
