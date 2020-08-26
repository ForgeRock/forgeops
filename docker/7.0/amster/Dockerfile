FROM gcr.io/forgerock-io/amster:7.1.0-8a4bbc995d288b43154eb5600c420e102b2c14d1

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
