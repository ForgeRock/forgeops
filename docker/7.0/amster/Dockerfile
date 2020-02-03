FROM gcr.io/forgerock-io/amster/pit1:7.0.0-b968ce3fa6bd2558a933ac012325584341a100cb

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
