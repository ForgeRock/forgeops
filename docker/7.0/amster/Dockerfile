FROM gcr.io/forgerock-io/amster:7.0.0-82dbc847fed69a8776398c5ec40f19569ff92494

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
