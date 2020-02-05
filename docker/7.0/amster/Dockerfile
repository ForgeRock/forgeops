FROM gcr.io/forgerock-io/amster/pit1:7.0.0-d2839a853b87797e961c5246207d05f4040e1a82

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
