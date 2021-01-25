FROM gcr.io/forgerock-io/amster/pit1:7.1.0-2020-15-107e3e07f353c8fcb902a75b78833541aeba0359

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
