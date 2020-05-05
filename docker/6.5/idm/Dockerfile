# Use publicly available am image for evaluation
FROM gcr.io/forgeops-public/idm-base:6.5

# Use a custom am-base image. See forgeops/docker/6.5/am-base/README
#FROM idm-base:latest

# Removes any existing conf files that might conflict with our config. This includes the embedded ds repo.
RUN rm -fr /opt/openidm/conf
ENV JAVA_OPTS "-XX:MaxRAMPercentage=75.0"
COPY --chown=forgerock:root . /opt/openidm
