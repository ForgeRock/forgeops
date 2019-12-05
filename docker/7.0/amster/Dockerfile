FROM gcr.io/forgerock-io/amster/pit1:7.0.0-9965d4cafae04d5e05514014ec8ff858f34aeeaf

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
