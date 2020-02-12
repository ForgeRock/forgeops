FROM gcr.io/forgerock-io/amster/pit1:7.0.0-1240c6cac5c6c0c8263b283adfc46da8894f95a5

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
