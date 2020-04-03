FROM gcr.io/forgerock-io/amster/pit1:7.0.0-c540a47850806c99dd3d5f9e8e089ea4587977ef

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
