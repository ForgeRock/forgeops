FROM gcr.io/forgerock-io/amster:7.1.0-IDCLOUD-3f811dbc73dbb3442b32ac723087c7fa70e67710

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
