FROM gcr.io/forgerock-io/amster:7.0.0-77a3719c799987e579243dad9e6dc6ccd69c8f39

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
