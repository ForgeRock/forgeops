FROM gcr.io/forgerock-io/amster/pit1:7.0.0-9d0597d2afce68bc1aac3a518033b06c0d299508

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
