FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8233d00d3ccb0a0f05ecf9a854fe7dc9273d9cea

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
