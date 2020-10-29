FROM gcr.io/forgerock-io/amster/pit1:7.1.0-9cb1f7c05447b73dc508560e9f6f48ea1aa64972

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
