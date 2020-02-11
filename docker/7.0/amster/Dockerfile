FROM gcr.io/forgerock-io/amster/pit1:7.0.0-c7cc1e17b14d00df7f72fca6581a624579cb8ccf

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
