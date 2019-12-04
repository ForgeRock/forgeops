FROM gcr.io/forgerock-io/amster/pit1:7.0.0-ebe3101f2718f663d4a53aa92b173d4ba18b128d

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
