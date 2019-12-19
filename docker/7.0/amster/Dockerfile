FROM gcr.io/forgerock-io/amster/pit1:7.0.0-56cf11301219e77599395d57e8020e47b063fdc8

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
