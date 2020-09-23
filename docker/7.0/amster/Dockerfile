FROM gcr.io/forgerock-io/amster/pit1:7.1.0-a3360d1bcd7d98c84c990ddaaceed8cc7acb799e

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
