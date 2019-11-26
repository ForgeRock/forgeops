# Use publicly available am image for evaluation
FROM gcr.io/forgerock-io/openidm:6.5.2

# Use a custom am-base image. See forgeops/docker/6.5/am-base/README
#FROM idm-base:latest

# Removes any existing conf files that might conflict with our config. This includes the embedded ds repo.
RUN rm -fr /opt/openidm/conf
ENV JAVA_OPTS "-server -Xmx1g"
COPY --chown=forgerock:root . /opt/openidm
