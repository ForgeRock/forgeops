FROM gcr.io/forgerock-io/ig/pit1:7.0.0-1d64e0d0f73ccc053694f0a872196a4ee8929ba8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
