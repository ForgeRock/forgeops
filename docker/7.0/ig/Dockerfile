FROM gcr.io/forgerock-io/ig:7.0.0-bce4c8fe93d670dc4c2ef67c9360625471dc8917

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
