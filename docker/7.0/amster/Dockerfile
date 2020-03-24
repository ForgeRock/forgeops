FROM gcr.io/forgerock-io/amster/pit1:7.0.0-d5ef8e805180a95abba8f292a27f357bd7175039

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
