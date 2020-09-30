FROM gcr.io/forgerock-io/amster:7.1.0-58b2bb7eecfb6a77e04bdf20467da206eaf4159a

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
