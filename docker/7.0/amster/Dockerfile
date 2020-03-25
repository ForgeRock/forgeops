FROM gcr.io/forgerock-io/amster:7.0.0-56a8c24053e15535caaadd0c1a67117645853452

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
