FROM gcr.io/forgerock-io/amster/pit1:7.0.0-46d88e358a80eed6930c25a1001b91078382e62e

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
