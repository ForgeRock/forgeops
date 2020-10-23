FROM gcr.io/forgerock-io/amster/pit1:7.1.0-efd039762eb4e32c51e6c96df1e3e7b9b98c7460

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
