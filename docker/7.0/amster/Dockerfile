FROM gcr.io/forgerock-io/amster/pit1:7.1.0-e0a03248e147746a4022e744f3a77b6e14c1b6d4

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
