FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8adf094585285d2f27332789c80ed770a6c4bc10

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
