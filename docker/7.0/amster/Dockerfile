FROM gcr.io/forgerock-io/amster:7.1.0-2020-15-38b3dc481e2731978a5ddde7cfe038cf97e80b3f

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
