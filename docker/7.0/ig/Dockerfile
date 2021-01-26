FROM gcr.io/forgerock-io/ig/pit1:7.1.0-11704d93b13cca92a2aeeacfffccc68be3dd6d26

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
