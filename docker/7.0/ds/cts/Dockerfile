FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-9aa7efe645963a3159dff14aaaf4f099a9d6714c
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# CLOUD-1955
#RUN find . -user root  && find . -name \*.wh