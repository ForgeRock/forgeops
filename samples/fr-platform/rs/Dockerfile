FROM forgerock-docker-public.bintray.io/forgerock/openig:6.0.0

ADD web.xml /usr/local/tomcat/webapps/ROOT/WEB-INF
ADD config /var/openig/config
ADD scripts /var/openig/scripts
ADD keystore.jks /var/openig
ADD wellKnownCheck.sh /

USER root

RUN chown -R forgerock /var/openig

USER forgerock
