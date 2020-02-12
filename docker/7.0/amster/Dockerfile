FROM gcr.io/forgerock-io/amster/pit1:7.0.0-4bc340d533d41136e8ffe53735a5c3620928d4d6

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
