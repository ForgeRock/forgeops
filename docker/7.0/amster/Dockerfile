FROM gcr.io/forgerock-io/amster:7.0.0-142335bfbb9bfb6fef9f8a47ec317bf90f5f5ee7

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
