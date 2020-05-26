FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-5b042b66e20f22c7cbe660667b038b8971193a19
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh