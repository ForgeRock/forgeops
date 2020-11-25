FROM gcr.io/forgerock-io/amster/pit1:7.1.0-266ee767420dad2dbbff12acf9b674085ad60a8b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
