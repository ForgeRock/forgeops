FROM gcr.io/forgerock-io/amster/pit1:7.1.0-c42df5c7e31a1a18f38789dd4531ce3924e9fe56

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
