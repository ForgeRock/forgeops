FROM gcr.io/forgerock-io/amster/pit1:7.1.0-bde09ee9f2b3c749bd7fb0502ad999e614e0f1b6

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
