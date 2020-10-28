FROM gcr.io/forgerock-io/amster/pit1:7.1.0-91c706c34c0d1959bd9235b63bc78bb2304440ad

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
