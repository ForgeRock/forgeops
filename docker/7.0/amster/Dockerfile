FROM gcr.io/forgerock-io/amster/pit1:7.0.0-74a1162f3cd5f2b41d076c260bfe200caf1b186d

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
