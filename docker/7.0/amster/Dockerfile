FROM gcr.io/forgerock-io/amster/pit1:7.1.0-ae945e16eef05ef3a4efde56c8c42ff239a1007b

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
