FROM gcr.io/forgerock-io/amster/pit1:7.0.0-6d9f44ca1edb9c9a0773daf398f79c0571fc7562

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
