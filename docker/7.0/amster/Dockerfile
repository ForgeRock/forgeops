FROM gcr.io/forgerock-io/amster/pit1:7.0.0-4709157aa4c0455468b80f5dd2309546fc3eb7af

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
