FROM gcr.io/forgerock-io/amster/pit1:7.1.0-b819341a1f1e10c9c4111cd0a61db3571b133465

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
