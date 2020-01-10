FROM gcr.io/forgerock-io/amster/pit1:7.0.0-f7f7b36eba1f61d9ebb1cea86ac5bca6fc3769ac

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
