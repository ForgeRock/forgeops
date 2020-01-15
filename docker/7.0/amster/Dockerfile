FROM gcr.io/forgerock-io/amster:7.0.0-e3b6c64ed12ab2ef0d03b88ddc20fb53b9930132

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
