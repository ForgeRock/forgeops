FROM gcr.io/forgerock-io/amster/pit1:7.0.0-df3d4624982ecb497297701a1a907d7a83ab29c8

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
