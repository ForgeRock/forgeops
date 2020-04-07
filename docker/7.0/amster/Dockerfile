FROM gcr.io/forgerock-io/amster/pit1:7.0.0-1900854ba47be7ea1fb897572e8fe627f6ea2dfe

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
