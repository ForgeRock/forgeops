FROM gcr.io/forgerock-io/ig:7.2.0-0542a09c662704231b466905990e23adf129329c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
