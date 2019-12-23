FROM gcr.io/forgerock-io/amster/pit1:7.0.0-f993c4441077e717acfe9a07305208ba854cfc4d

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
