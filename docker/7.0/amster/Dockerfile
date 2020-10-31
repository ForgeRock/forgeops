FROM gcr.io/forgerock-io/amster:7.1.0-b3ada719b1969e186f1edd6b3c876b50f0683161

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
