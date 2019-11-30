FROM gcr.io/forgerock-io/amster:7.0.0-9443891d8fa215c2e07f8ef7ac733ebbf0d1c8ca

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
