FROM gcr.io/forgerock-io/amster:7.0.0-37c45b4d11984014498cb35e3925d0a3e0c053ff

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
