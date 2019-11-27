FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8c8bd3d77baaa923dff4339188b48852d9d2a728

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
