FROM gcr.io/forgerock-io/ds-empty:7.0.0-c070ca32bd967ed836e0c7d96dbeaf2c4db61cce
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh