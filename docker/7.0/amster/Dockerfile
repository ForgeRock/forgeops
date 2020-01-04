FROM gcr.io/forgerock-io/amster:7.0.0-73e57895acc1b87cc4e4140a07e4679ecb3ef181

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
