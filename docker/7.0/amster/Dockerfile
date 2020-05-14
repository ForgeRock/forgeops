FROM gcr.io/forgerock-io/amster:7.0.0-1ba49f89bf13e3d0543c80fd5fa284e32b5fd9e4

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
