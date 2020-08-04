FROM gcr.io/forgerock-io/amster/pit1:7.0.0-beb20d72ad0d16ab9e150a7dea1b45d37209edef

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
