FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-e0dd3c53d97b1f6450dc02ed0b11f39e202e354a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
