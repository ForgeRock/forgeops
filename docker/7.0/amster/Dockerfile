FROM gcr.io/forgerock-io/amster/pit1:7.0.0-e5454907c5cc1aa8eb7b04a16a6aa91e34e71cf7

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
