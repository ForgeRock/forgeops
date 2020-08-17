FROM gcr.io/forgerock-io/amster/pit1:7.1.0-7a2db86b1bdaaf69a047e5af64687acdc90f48ad

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
