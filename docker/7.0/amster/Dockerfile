FROM gcr.io/forgerock-io/amster/pit1:7.0.0-13f4f54492b5f264f3665be15b02c18cafbd07a5

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
