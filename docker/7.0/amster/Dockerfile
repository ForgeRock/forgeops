FROM gcr.io/forgerock-io/amster/pit1:7.1.0-2020-15-96b37660ce228a970cfd4cc5e4747db051a3bf42

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
