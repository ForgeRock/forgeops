FROM gcr.io/forgerock-io/amster/pit1:7.1.0-1dca94a0a406610ee985049f7f78492319bc7f67

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
