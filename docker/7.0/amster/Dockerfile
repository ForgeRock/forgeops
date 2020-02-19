FROM gcr.io/forgerock-io/amster/pit1:7.0.0-b9ddf8dde39cbd51f4c6776bd558eedd83b484f4

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
