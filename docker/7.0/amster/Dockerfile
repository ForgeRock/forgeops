FROM gcr.io/forgerock-io/amster/pit1:7.0.0-6d11b3617f5efd8b9fe584020f4d7faf6384dd6d

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
