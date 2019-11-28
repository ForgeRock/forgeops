FROM gcr.io/forgerock-io/amster/pit1:7.0.0-79e9b8061e8d5cc0feee44fbc4b3075b61d190a3

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
