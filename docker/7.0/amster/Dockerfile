FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8c91c469d869143eb050762766534b674bf856bf

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
