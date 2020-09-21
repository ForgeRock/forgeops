FROM gcr.io/forgerock-io/amster/pit1:7.1.0-460ae77db9adac9bd9f394705d5947a10a93f340

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
