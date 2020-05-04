FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-790620fbfc56c3bdfe613d24ebebb1f3a0919523
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# CLOUD-1955
#RUN find . -user root  && find . -name \*.wh