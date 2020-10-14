FROM gcr.io/forgerock-io/amster/pit1:7.1.0-92f88bceca6742bd1ddc6d5f1a14e3a9faa5eb36

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
