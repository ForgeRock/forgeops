FROM gcr.io/forgerock-io/amster/pit1:7.0.0-27030adc9663daef65189f9444966ff596b23fa2

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
