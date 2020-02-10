FROM gcr.io/forgerock-io/amster/pit1:7.0.0-7ca4fc6c9c2540403f41b999cc8328b65eb38468

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
