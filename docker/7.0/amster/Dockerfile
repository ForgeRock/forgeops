FROM gcr.io/forgerock-io/amster/pit1:7.0.0-30aaf82645e1c020a8faf837a21f8ff49ba8315c

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
