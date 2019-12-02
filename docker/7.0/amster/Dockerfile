FROM gcr.io/forgerock-io/amster/pit1:7.0.0-fda71db927c101cca55232e7c6f4dc1bfc8bc11d

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
