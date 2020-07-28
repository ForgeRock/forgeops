FROM gcr.io/forgerock-io/amster/pit1:7.0.0-6010ec721d50c4cb20cdc145db75037f0ae74738

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

