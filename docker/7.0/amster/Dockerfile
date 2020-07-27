FROM gcr.io/forgerock-io/amster/pit1:7.0.0-03b48a9917ea034a6a982ff214363ba0380c8b51

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

