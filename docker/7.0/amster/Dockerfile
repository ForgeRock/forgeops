FROM gcr.io/forgerock-io/amster/pit1:7.0.0-6ad57ebe9289f66023154eae0b87e7ecb6afd2b7

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
