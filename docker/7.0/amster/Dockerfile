FROM gcr.io/forgerock-io/amster:7.0.0-aa1782243114a5e9e694f7d7a6303eb6f69be126

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
