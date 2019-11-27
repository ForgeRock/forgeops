FROM gcr.io/forgerock-io/amster/pit1:7.0.0-1d56c89714009cbd5161b68ead37dd47fcbc2e7a

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
