FROM gcr.io/forgerock-io/amster/pit1:7.1.0-PAAS-GA-c47615f6dc33d86925f0a28b8520f5d4ec0ffc9d

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
