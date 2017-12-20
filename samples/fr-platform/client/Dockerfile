FROM forgerock-docker-public.bintray.io/forgerock/openig:6.0.0

ADD config /var/openig/config
ADD scripts /var/openig/scripts
ADD wellKnownCheck.sh /

USER root

RUN chown -R forgerock /var/openig

USER forgerock

EXPOSE 5005
ENV JPDA_ADDRESS 5005
ENV JPDA_TRANSPORT dt_socket
