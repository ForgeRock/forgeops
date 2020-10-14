FROM gcr.io/forgerock-io/amster/pit1:7.1.0-efbb7bc53f0571de8453e761bcbd1ee0e27422d2

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
