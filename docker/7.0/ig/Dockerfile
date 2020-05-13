FROM gcr.io/forgerock-io/ig-standalone:7.0.0-f770e571701d771c2c93e57eb241d30039f36c5d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
