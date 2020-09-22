FROM gcr.io/forgerock-io/amster/pit1:7.1.0-0c1acc7f676ee95935bed3c6f8a386cd6d9699db

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
