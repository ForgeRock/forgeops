FROM gcr.io/forgerock-io/amster/pit1:7.0.0-3f1364b974dad9f09f2835dcd7c007b29b35c88e

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
