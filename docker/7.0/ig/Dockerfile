FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-05cf355760219cd0d13335560c7562aa018933fa

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
