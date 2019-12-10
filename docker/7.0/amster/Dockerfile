FROM gcr.io/forgerock-io/amster:7.0.0-a2c0b492f7620fff48183fc657041463762930ec

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
