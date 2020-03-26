FROM gcr.io/forgerock-io/amster/pit1:7.0.0-2277ab5e02c25ff0ebe196662090a96dda715dfa

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
