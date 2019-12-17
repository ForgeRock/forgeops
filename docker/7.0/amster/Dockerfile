FROM gcr.io/forgerock-io/amster:7.0.0-0e24e86c37d1564512e895064d3283cf4e188e10

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
