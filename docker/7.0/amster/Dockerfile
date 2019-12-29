FROM gcr.io/forgerock-io/amster:7.0.0-b09398a1f6e507c7b009ea7b22a36e4d4a5a437a

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
