FROM gcr.io/forgerock-io/amster/pit1:7.1.0-74c2754d554166cb3f887ac66e94d9ef3f58e931

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
