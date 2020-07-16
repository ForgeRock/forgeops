FROM gcr.io/forgerock-io/amster:7.0.0-0ef9c985ce31d62e8fd2683a6080b372899e19ad

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

