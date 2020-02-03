FROM gcr.io/forgerock-io/amster/pit1:7.0.0-62dc5778167cd7d74a438af6429e33bc397a9ce8

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
