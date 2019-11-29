FROM gcr.io/forgerock-io/amster/pit1:7.0.0-9b935da17b441d92f03f240b434b7c7fa1750854

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
