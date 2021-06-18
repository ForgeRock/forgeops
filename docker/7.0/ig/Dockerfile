FROM gcr.io/forgerock-io/ig/pit1:7.2.0-1059ab7877c6be9073b02b5e0a48f67fb049d3ee

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
