FROM gcr.io/forgerock-io/amster/pit1:7.1.0-5141e357eefcbe066652f16b98da7116d1346e91

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
