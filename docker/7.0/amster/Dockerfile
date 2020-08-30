FROM gcr.io/forgerock-io/amster:7.1.0-61b218a70484e282d5e942c5cfdbf07dfd8c1382

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
