FROM gcr.io/forgerock-io/amster/pit1:7.0.0-2f5d055f1eacd0f425a7262c77a22d577c2a52e4

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
