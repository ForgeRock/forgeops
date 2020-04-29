FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-728f32c5537c5a173b9c994a3460b6b1697b8b8e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
