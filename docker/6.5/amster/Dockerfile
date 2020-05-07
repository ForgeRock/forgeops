FROM  gcr.io/forgeops-public/amster-base:6.5

ENV SERVER_URI /am

USER root
#RUN apk add --update --no-cache openldap-clients jq
RUN apt-get install -y ldap-client jq
# We replace some of the entry point scripts with others need for skaffold.
COPY  --chown=forgerock:0 . /opt/amster
USER forgerock

# Use ENTRYPOINT with -x to support Windows deployments
# Without it, Docker does not know docker-entrypoint.sh is executable on Windows
ENTRYPOINT ["bash", "-x", "/opt/amster/docker-entrypoint.sh"]
CMD ["configure"]
