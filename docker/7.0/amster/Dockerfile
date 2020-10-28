FROM gcr.io/forgerock-io/amster/pit1:7.1.0-0507c425f814dba8f67a8a28a781fe400b721527

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
