FROM gcr.io/forgerock-io/amster:7.1.0-7b101cf0996555db7077dd8ea68998eb879c5668

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
