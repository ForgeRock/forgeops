FROM gcr.io/forgerock-io/amster/pit1:7.0.0-b5fa3fb45e215e78e207be012a8ac3265c30c6be

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

