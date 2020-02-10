FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8a430194fe855c2daf3486191b29989e6212365b

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
