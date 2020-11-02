FROM gcr.io/forgerock-io/amster/pit1:7.1.0-50b8d28260c97899133ba7677a7b7cf88411c78c

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
