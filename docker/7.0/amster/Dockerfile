#FROM gcr.io/forgerock-io/amster/pit1:7.0.0-28cd5f66d11a9c6b6fbfbf3421800615bbf753fd
FROM gcr.io/forgerock-io/amster/pit1@sha256:a636ced598af735a328f8f535601f6ba8f24f32e61574508385f1230aa7bdb01

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
