FROM gcr.io/forgerock-io/amster/pit1:7.1.0-a660c8fbf736c1335a5df5c5f82655cb293d86bc

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
