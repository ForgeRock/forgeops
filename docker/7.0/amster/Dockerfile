FROM gcr.io/forgerock-io/amster:7.0.0-d3f42c91bcb69ba165dd7cd92d9aa3e04031145c

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
