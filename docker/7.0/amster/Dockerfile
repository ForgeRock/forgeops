FROM gcr.io/forgerock-io/amster/pit1:7.0.0-51b5d60dd24eab5894f48d8f77ab41ef020aebe8

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
