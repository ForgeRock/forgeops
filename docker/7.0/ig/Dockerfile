FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2dade11b405914a1931a0f6947e6ecd6a1084793

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
