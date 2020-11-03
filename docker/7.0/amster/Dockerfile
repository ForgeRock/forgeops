FROM gcr.io/forgerock-io/amster/pit1:7.1.0-21cd0d98f60214613ea322581ca1a87261a550cb

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
