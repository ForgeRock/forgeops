FROM gcr.io/forgerock-io/amster/pit1:7.0.0-85fbb4870f892cb2a095cb0490b9a6dc4e55213e

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
