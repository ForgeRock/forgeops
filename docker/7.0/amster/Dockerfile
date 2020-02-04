FROM gcr.io/forgerock-io/amster/pit1:7.0.0-cd882247cf64d9c7c1a62074bfe57687b1e23a8b

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
