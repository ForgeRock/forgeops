FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-ff04c9739d798eb4562428df323c30f1a587e90b
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh