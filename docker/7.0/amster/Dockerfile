FROM gcr.io/forgerock-io/amster/pit1:7.0.0-741d0b43cb735409cd7cf13b12cbc5cd48f2057e

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
