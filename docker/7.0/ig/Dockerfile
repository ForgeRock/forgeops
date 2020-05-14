FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-bce48b5e6753704d58cf21f2e031211976abaa5f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
