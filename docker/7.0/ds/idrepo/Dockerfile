FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-3611cd579e40af4eb72594f08fb27b3ad77e4194
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh