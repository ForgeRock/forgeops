FROM gcr.io/forgerock-io/amster/pit1:7.0.0-b911cfc1d7f21c30cd3caf25159fba5293b4db3a

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
