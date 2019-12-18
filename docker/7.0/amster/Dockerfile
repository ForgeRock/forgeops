FROM gcr.io/forgerock-io/amster/pit1:7.0.0-4ea6ee69db9801cf2321c3dded19c6f7e9a0dbd2

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
