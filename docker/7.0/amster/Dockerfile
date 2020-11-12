FROM gcr.io/forgerock-io/amster/pit1:7.1.0-1139895ec39b7420b27d18e750d0daa36c8a1377

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
