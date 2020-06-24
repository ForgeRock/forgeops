FROM gcr.io/forgerock-io/amster/pit1:7.0.0-940664a4a8ae38e99ce6ee9f5425d491646959f8

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
