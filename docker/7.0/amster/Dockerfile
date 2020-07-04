FROM gcr.io/forgerock-io/amster/pit1:7.0.0-8301e3d99fe410cf1e89a32e02a6c60b9b9a4d5d

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

