FROM gcr.io/forgerock-io/amster/pit1:7.1.0-5c2a48fc600ee51c1c67f08a00c1893b4a323434

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
