FROM gcr.io/forgerock-io/amster:7.1.0-0f75e679c9134d75bac58600bf24f225a1c73e45

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
