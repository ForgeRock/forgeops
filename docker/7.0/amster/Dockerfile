FROM gcr.io/forgerock-io/amster/pit1:7.0.0-d0215a6d404bf8c252b40a747594cb0dc2a7eac3

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

