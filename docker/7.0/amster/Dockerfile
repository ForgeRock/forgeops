FROM gcr.io/forgerock-io/amster/pit1:7.0.0-2661f1804628dc7b17ab569e8e2a8f89aa7163f4

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
