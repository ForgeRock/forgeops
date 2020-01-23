FROM gcr.io/forgerock-io/amster/pit1:7.0.0-2f528d0a3626b8dfcefec1d1c6405c6317a24d35

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
