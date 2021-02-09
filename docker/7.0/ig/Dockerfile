FROM gcr.io/forgerock-io/ig/pit1:7.1.0-5f97522b4a78b64fb4a63b6fe0f8c00963f71774

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
