FROM forgerock-docker-public.bintray.io/forgerock/openig:6.5.0-RC1

ADD config /var/openig/config
ADD scripts /var/openig/scripts
ADD keystore.jks /var/openig

USER root

RUN chown -R forgerock /var/openig

USER forgerock
