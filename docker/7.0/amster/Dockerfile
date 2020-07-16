FROM gcr.io/forgerock-io/amster/pit1:7.0.0-7a2542d1eb0c92350a1ef6b36cf8feccea5ca348

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

