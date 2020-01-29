FROM gcr.io/forgerock-io/amster:7.0.0-a34e79f50f68a30b8ea3651753878e347e373a6a

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
