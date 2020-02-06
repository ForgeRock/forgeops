FROM gcr.io/forgerock-io/amster/pit1:7.0.0-908d1bd20c82034d9c5cbdbeba0e4d61203eefa9

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
