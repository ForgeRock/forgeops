FROM gcr.io/forgerock-io/amster/pit1:7.1.0-7ff37841fbf3bdbf1ba311cc89cc5ca6e5c90d81

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
