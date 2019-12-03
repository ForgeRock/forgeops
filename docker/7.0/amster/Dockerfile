FROM gcr.io/forgerock-io/amster/pit1:7.0.0-5a5f3cdec570cc7474332daa4b94c3c695c82b0d

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
