FROM gcr.io/forgerock-io/amster:7.0.0-72b09753e054dc56e7de6b08851840130b54b39c

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
