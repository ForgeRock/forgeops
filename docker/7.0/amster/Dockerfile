FROM gcr.io/forgerock-io/amster/pit1:7.0.0-0ad21e1b1e67289bcf2a4e867ea86e98d877de18

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
