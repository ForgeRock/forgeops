FROM gcr.io/forgerock-io/amster/pit1:7.0.0-d7f794bd0d1ae4ea93f7051dceea4d07209c8f8d

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
