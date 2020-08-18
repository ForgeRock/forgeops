FROM gcr.io/forgerock-io/amster/pit1:7.1.0-72e4da5e992337c46c1782f79855016198e44578

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
