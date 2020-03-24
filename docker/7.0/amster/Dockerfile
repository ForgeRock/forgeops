FROM gcr.io/forgerock-io/amster/pit1:7.0.0-07bc0e9b97b790c745baed976c753ad761b0ebde

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
