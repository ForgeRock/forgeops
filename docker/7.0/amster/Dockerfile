FROM gcr.io/forgerock-io/amster:7.1.0-PAAS-GA-a7f1b8f64371cdc717ab12b815afc39e5be85454

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
