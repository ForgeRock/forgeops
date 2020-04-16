FROM gcr.io/forgerock-io/amster/pit1:7.0.0-f258558332cf07dc2bb88af8eb82f92ed55e2b3c

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
