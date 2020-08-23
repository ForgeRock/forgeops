FROM gcr.io/forgerock-io/amster/pit1:7.1.0-b6e759199d54a7801b2ec7afb876e573771f77fc

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
