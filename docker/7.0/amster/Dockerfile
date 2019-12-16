FROM gcr.io/forgerock-io/amster:7.0.0-510b29e4595148aeee0d6141e93919db7dc8c9a3

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
