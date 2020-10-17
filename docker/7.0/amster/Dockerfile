FROM gcr.io/forgerock-io/amster:7.1.0-ea2fc6d5ffa72eab07db08dc945f8b64478ca3e1

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
