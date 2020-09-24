FROM gcr.io/forgerock-io/amster:7.1.0-0cfad09090a8f070ea329cb9732fcc2ab12a60a7

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
