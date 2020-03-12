FROM gcr.io/forgerock-io/amster/pit1:7.0.0-e648d18f06f0c7629d86513ba170a00d38fc9497

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
