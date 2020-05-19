FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-bc93d0f14b785c12a085e175bd667cf5da2fbb8d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
