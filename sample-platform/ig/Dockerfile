# docker build -t ig:fullstack ig

FROM forgerock/openig:5.5.0

ADD config /var/openig/config
ADD scripts /var/openig/scripts

USER root

RUN chown -R forgerock /var/openig

USER forgerock
