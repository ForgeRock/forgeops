FROM gcr.io/forgerock-io/amster/pit1:7.0.0-363b163e4bd1e3aef68d6eabde317c9c321775ca

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
