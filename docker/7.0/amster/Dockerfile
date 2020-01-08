FROM gcr.io/forgerock-io/amster/pit1:7.0.0-2226adeb6830fa96e2daf126accc161ad4c782b5

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
