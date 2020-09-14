FROM gcr.io/forgerock-io/amster/pit1:7.1.0-dc66d47b47841e585967ffb65d22e3959e25f715

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
