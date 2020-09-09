FROM gcr.io/forgerock-io/amster/pit1:7.1.0-918396b708b0b3e912797151c67f8a2f1b47d4cc

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
