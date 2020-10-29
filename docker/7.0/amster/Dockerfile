FROM gcr.io/forgerock-io/amster/pit1:7.1.0-fb183a871b36232cf8f382d69c1aa52bac53d8ec

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
