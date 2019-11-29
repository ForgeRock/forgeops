FROM gcr.io/forgerock-io/amster/pit1:7.0.0-977dc136255ae8004869ce8ae38de74a33a2116f

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
