FROM gcr.io/forgerock-io/amster/pit1:7.0.0-4765b08116f2f9b6059d49fa11968b8048b707f9

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
