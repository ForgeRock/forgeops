FROM gcr.io/forgerock-io/amster/pit1:7.0.0-2b1a765c97389516703db47ffccba8a07b70090b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

