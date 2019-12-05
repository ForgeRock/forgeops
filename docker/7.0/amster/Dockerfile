FROM gcr.io/forgerock-io/amster/pit1:7.0.0-7e3f0f5e209b3566f0fe7e4edfacedcb95288f07

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
