FROM gcr.io/forgerock-io/ds-empty:7.0.0-14dce1948e40e77f49e1ec08b97436bb432321b6
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
