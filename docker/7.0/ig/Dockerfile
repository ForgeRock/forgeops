FROM gcr.io/forgerock-io/ig:7.2.0-2021-6-3fa8e292f8a29c04f3c9773560ecc3ed5ed6fe3b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
