FROM gcr.io/forgerock-io/amster/pit1:7.1.0-60777eb8b57c5a0f3e0d59717b200b59cfb75b63

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
