FROM gcr.io/forgerock-io/amster/pit1:7.0.0-a5c329bb75003ccdc18f41239e2dc7747f496a37

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
