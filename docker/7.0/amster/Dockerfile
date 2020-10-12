FROM gcr.io/forgerock-io/amster/pit1:7.1.0-PAAS-GA-cab4e8848bef4b350691100d71b722fdb99724ce

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
