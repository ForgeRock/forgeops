FROM gcr.io/forgerock-io/amster/pit1:7.0.0-2c94d6b0f8fa79b87e808dd17def783093cbc05e

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
