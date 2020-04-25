FROM gcr.io/forgerock-io/ds-empty:7.0.0-18145b88f2405e5041610031d5a6c44ca605a3ca
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# CLOUD-1955
#RUN find . -user root  && find . -name \*.wh