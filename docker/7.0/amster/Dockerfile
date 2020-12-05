FROM gcr.io/forgerock-io/amster:7.1.0-2020-15-c2984c71f6f7e308771b98b3ae0c38e37f1783e6

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
