FROM gcr.io/forgerock-io/amster/pit1:7.0.0-7ce3f31c4b5bf7263f844d94bc15ff8967aa7c41

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
