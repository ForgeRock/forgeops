FROM gcr.io/forgerock-io/amster/pit1:7.0.0-d30262eb9a6a66d310506c61b2f94597d44f64e8

USER root
RUN apk add --update --no-cache openldap-clients jq
USER forgerock

ENV SERVER_URI /am

COPY  --chown=forgerock . /opt/amster
