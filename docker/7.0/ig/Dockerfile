FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-395d90f3bc03534787ca34467ed853c72379a5ec

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
