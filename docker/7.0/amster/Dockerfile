FROM gcr.io/forgerock-io/amster/pit1:7.1.0-e3931e8d5933bef0b8d0ffb88ce068c6ffd145ac

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
