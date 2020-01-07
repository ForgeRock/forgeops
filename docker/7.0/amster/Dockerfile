FROM gcr.io/forgerock-io/amster/pit1:7.0.0-48b360d449c3a893c1ad66c0669cbe4653e0686f

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
