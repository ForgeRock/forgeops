FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-592f1799b8071b2c389bba16126a4eff3c53ff4e
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root idrepo /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh