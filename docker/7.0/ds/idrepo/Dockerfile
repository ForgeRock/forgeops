FROM gcr.io/forgerock-io/ds:7.1.0-bd1f570b7e69b3da55dd39578448a5e92aaf0f4c

# If you want to update any o/s software, or require root access, uncomment the lines below
# Ensure that the /opt/opendj is owned by forgeorock:root
# USER root
# RUN chown -R forgerock:root /opt/opendj
# USER forgerock
WORKDIR  /opt/opendj

COPY --chown=forgerock:root common  /opt/opendj/
COPY --chown=forgerock:root idrepo  /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts

# To experiment with a modified entrypoint, uncomment:
# COPY --chown=forgerock:root scripts/docker-entrypoint.sh /opt/opendj

ARG profile_version
RUN bin/setup.sh "$profile_version" && \
    bin/relax-security-settings.sh  && \
    rm bin/setup.sh bin/relax-security-settings.sh
