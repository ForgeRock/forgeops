FROM gcr.io/forgerock-io/amster/pit1:7.0.0-1953aa907ba8727dd74c2d711672f9da3ed42a81

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
