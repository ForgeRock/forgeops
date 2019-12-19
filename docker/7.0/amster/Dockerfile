FROM gcr.io/forgerock-io/amster/pit1:7.0.0-89b3ea47cb2bde77e778f337138c8bd16a8c4cd7

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
