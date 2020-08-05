FROM gcr.io/forgerock-io/amster/pit1:7.0.0-60aa8a23e90c933094592bd05319ad51555f0cf9

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
