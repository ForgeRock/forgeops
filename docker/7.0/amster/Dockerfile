FROM gcr.io/forgerock-io/amster/pit1:7.1.0-0d4e8195f5019d755b69c3c76153e391db774fee

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
