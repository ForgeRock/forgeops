FROM gcr.io/forgerock-io/amster/pit1:7.0.0-667537a897058a65b32395ccbfe8b3a601d9b992

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
