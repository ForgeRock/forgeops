FROM gcr.io/forgerock-io/amster/pit1:7.0.0-c6bd67af2b8717f25e06fe0a6f3508cc5ac44ebc

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
