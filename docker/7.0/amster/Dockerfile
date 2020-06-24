FROM gcr.io/forgerock-io/amster/pit1:7.0.0-32672071cef678dd380863bd54d65888f4351b66

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
