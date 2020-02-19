FROM gcr.io/forgerock-io/amster/pit1:7.0.0-1e5f2ca3e28a46d58c771dc58f6d26258b2c7d5f

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
