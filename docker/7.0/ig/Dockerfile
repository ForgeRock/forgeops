FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-1d2555a931f371175ba62d478851f16c939549c8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
