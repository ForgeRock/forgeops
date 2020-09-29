FROM gcr.io/forgerock-io/amster/pit1:7.1.0-c395479003926b691cb9428fbafaa23c2e280a7c

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
