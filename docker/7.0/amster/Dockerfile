FROM gcr.io/forgerock-io/amster/pit1:7.1.0-7b6fd9e9e182a3df3e43bf38c8b3f12f327945d1

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
