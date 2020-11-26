FROM gcr.io/forgerock-io/amster/pit1:7.1.0-47bccdccd1b2fe0419f5b2765d94cb7a4a0a796a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
