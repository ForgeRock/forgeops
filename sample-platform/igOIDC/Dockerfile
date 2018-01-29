FROM forgerock/openig:5.5.0

ADD config /var/openig/config
ADD scripts /var/openig/scripts
ADD wellKnownCheck.sh /

USER root

RUN chown -R forgerock /var/openig

USER forgerock
