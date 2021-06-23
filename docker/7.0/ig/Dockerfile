FROM gcr.io/forgerock-io/ig:7.2.0-489a505731e05b6f943cfc5d4a828ee1a0332bcd

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
