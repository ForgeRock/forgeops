FROM gcr.io/forgerock-io/amster/pit1:7.1.0-7d86b998552af51af904224522bae62395f65c8e

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
