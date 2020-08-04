FROM gcr.io/forgerock-io/amster/pit1:7.0.0-431241ac6096a25e459882ff76cdf77eb101d4aa

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
