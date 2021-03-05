FROM gcr.io/forgerock-io/ig/pit1:7.1.0-335a8560f5ec66357645f0fe06b6bbfe6f8f2592

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
