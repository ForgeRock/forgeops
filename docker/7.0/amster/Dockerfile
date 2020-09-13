FROM gcr.io/forgerock-io/amster/pit1:7.1.0-abede2578c68f86bbc259dc293a1998076faf48e

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
