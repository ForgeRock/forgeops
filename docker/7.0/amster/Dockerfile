FROM gcr.io/forgerock-io/amster/pit1:7.0.0-f873f6b23b56c3eabc52f631c6ef7a8754744b57

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
