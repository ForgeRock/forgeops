FROM gcr.io/forgerock-io/ig/pit1:7.2.0-d8fd4a4a7297266ed185cf3f9de75dae08c1e5f0

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
