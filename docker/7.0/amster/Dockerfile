FROM gcr.io/forgerock-io/amster/pit1:7.0.0-12e2e0e750058f388638dcbe73a0102dbf939180

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
