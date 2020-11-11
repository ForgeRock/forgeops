FROM gcr.io/forgerock-io/amster/pit1:7.1.0-IDCLOUD-9dbceaad6e6676f446f339dbd021f97c17a0444f

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
