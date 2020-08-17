FROM gcr.io/forgerock-io/amster/pit1:7.1.0-81bf45dc094ffddd0eb318c8429cdadcabc57850

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
