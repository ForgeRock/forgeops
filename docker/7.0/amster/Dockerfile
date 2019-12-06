FROM gcr.io/forgerock-io/amster/pit1:7.0.0-c22faa45be229ad4afff764e4c8b631fc7a7d4a3

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
