FROM gcr.io/forgerock-io/amster/pit1:7.1.0-047da8872ad937814c844b8841ee9292fa83aa07

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
