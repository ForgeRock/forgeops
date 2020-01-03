FROM gcr.io/forgerock-io/amster/pit1:7.0.0-4b5f7d998f6aaa04266d997551aad647aea316e5

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
