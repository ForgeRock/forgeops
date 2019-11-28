FROM gcr.io/forgerock-io/amster/pit1:7.0.0-642cc1da9112df04724566a86119e05b9bc517da

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
