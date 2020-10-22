FROM gcr.io/forgerock-io/amster:7.1.0-490c9c5f4e501a5163cf3e4432d4550a478f3239

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
