FROM gcr.io/forgerock-io/ig-standalone:7.0.0-c5f6a70d4d60365166093ad9262a4f833b8a6cdc

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
