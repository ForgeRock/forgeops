FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-8a9e1417bf5c1b8dea649c70dcf621570ceaf3ab

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
