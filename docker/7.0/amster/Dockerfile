FROM gcr.io/forgerock-io/amster/pit1:7.0.0-c747a9248be37a3164e63f4d41466ff740e9f502

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
