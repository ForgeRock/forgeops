FROM gcr.io/forgerock-io/amster/pit1:7.0.0-3d9b893dc615a8653b962e7f4a975b6bbbce6e56

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
