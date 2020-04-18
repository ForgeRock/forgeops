FROM gcr.io/forgerock-io/amster:7.0.0-220a9350ca666b71699504af5042f3c8444c530b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
