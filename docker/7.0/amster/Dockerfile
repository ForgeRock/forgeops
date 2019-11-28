FROM gcr.io/forgerock-io/amster/pit1:7.0.0-20615e6be1cfcd2b90b287f3fbc03a0a6e9153cf

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
