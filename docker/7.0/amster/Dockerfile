FROM gcr.io/forgerock-io/amster/pit1:7.1.0-2360f674ed9de3abae0081524055b3b1cadbe579

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
