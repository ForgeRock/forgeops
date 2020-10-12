FROM gcr.io/forgerock-io/amster/pit1:7.1.0-b52d33489792dc4f7641dc9dfdd9eadf9c15a020

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
