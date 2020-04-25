FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-097c1cca68f2b339349f4096a72a158711eead58

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
