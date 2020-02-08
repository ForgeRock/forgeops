FROM gcr.io/forgerock-io/amster/pit1:7.0.0-0b0767126df29ebbeca30e40c1281863521d4259

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
