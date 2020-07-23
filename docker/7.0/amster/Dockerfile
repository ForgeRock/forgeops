FROM gcr.io/forgerock-io/amster/pit1:7.0.0-5dd2bf79e2ab2667739c9053fc8f16e1d938ec65

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

