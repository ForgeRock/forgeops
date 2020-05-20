FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-664ceb590c3edd324f111e9d2e2356d74c4e5230
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh