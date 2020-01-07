FROM gcr.io/forgerock-io/amster/pit1:7.0.0-ac633f6e2693ccf1a47ef80da5934e75895192e2

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
