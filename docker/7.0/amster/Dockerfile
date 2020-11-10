FROM gcr.io/forgerock-io/amster/pit1:7.1.0-df91fcfbaa7c311878d7da45fdb0b1494faefc94

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
