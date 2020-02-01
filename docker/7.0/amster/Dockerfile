FROM gcr.io/forgerock-io/amster:7.0.0-77a0868f00553fd9eec33cf4b19456b98d8deb13

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
