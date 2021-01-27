FROM gcr.io/forgerock-io/ig/pit1:7.1.0-31fdd2d7118742158f4217c8a1df699b291256ad

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
