FROM gcr.io/forgerock-io/amster/pit1:7.0.0-d97405b3508d754fe11f3735f2e483e052ed55b2

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
