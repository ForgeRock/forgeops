FROM gcr.io/forgerock-io/amster:7.1.0-f0d1946a6610cbd073a3b8189aceb044bcfd2218

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
