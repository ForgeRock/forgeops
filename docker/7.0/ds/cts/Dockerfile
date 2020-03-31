FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-afff747be66bda50061d3bcd88bb2f8968c819c6
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
