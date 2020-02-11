FROM gcr.io/forgerock-io/amster/pit1:7.0.0-05b95a917edbe1629fad0fc24541c61e77b2922e

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
