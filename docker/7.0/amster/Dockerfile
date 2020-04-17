FROM gcr.io/forgerock-io/amster/pit1:7.0.0-fc0a015408f8ff67ec1cef5be2bc72c4f9246e7b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
