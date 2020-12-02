FROM gcr.io/forgerock-io/amster/pit1:7.1.0-91f0d51a9e72be4b0f891bd2d7394eedc4c61b86

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
