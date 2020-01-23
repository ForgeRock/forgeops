FROM gcr.io/forgerock-io/amster/pit1:7.0.0-31d3a7a3c97c04948b012d27a94bdd83b6064a46

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
