FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-97a4fc5f6432404cfd0239e98049b38b45c429df
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh