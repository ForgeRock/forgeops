FROM gcr.io/forgerock-io/amster:7.0.0-314bae51df7af69c45c7ba308b1533d4d474b137

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
