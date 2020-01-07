FROM gcr.io/forgerock-io/amster/pit1:7.0.0-037454bd87fe7e8d4c4e69b63dd48f2ee3d01964

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
