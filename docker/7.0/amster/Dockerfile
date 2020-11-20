FROM gcr.io/forgerock-io/amster/pit1:7.1.0-2020-14-5d6b8f9335affcaccf5766755247eb7093487885

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
