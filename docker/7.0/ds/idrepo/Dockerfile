FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-1bdb774c10f9dabfa4f0028a9e8d209aa2d2ab99
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
