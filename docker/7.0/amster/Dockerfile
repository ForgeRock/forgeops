FROM gcr.io/forgerock-io/amster/pit1:7.0.0-ab8d75edaceff5d00bc62fd082737d06840eac13

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
