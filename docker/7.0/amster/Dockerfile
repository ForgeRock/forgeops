FROM gcr.io/forgerock-io/amster/pit1:7.0.0-106c064e9b6dbd28b97b4ccd834e6f664184827d

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
