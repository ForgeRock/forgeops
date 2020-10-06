FROM gcr.io/forgerock-io/amster/pit1:7.1.0-e1f90a9775698f1ff471c70f9e4e476a81318494

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
