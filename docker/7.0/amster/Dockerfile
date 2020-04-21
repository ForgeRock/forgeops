FROM gcr.io/forgerock-io/amster/pit1:7.0.0-28cd5f66d11a9c6b6fbfbf3421800615bbf753fd

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
