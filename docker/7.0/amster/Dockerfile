FROM gcr.io/forgerock-io/amster/pit1:7.1.0-2020-14-1ea0a4aad7c880efa9d7fabfdb668ed03bd1639c

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
