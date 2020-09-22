FROM gcr.io/forgerock-io/amster/pit1:7.1.0-a99685337d2ed98d8e09b9a65e94954cd736a689

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
