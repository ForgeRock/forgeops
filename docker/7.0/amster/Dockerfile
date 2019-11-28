FROM gcr.io/forgerock-io/amster/pit1:7.0.0-b32c2a958e61d7f8071922633d7a3a9e8ce6a9e2

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
