FROM gcr.io/forgerock-io/amster/pit1:7.1.0-702e49a68771895afeae96a2ce25a0a196ea5538

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
