FROM gcr.io/forgerock-io/amster/pit1:7.0.0-7e5194277f89b0c210d8ca3dd2bc37970711f292

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
