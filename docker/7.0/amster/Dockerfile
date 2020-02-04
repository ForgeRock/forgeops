FROM gcr.io/forgerock-io/amster/pit1:7.0.0-9815eed9251470b1a46c01276bd06058b592e170

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
