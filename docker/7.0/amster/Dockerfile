FROM gcr.io/forgerock-io/amster/pit1:7.0.0-0745eecfd6f2c8e36cf3babed44cb11314976519

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
