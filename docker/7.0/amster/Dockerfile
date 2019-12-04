FROM gcr.io/forgerock-io/amster:7.0.0-cdcf4d4893624bd1a5e31a0bedef50ed1a8b0da4

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
