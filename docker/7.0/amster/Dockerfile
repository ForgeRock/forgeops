FROM gcr.io/forgerock-io/amster/pit1:7.0.0-6b2fd787c25f00fa4ba157d6569fad802e411d8e

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
