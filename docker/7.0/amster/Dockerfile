FROM gcr.io/forgerock-io/amster/pit1:7.1.0-06d69e156c70b09eeb6d5252b58fa708f795abdd

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
