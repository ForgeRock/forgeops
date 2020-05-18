FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-07a274c35beb64c757e45809351da7fbe1e633d8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
