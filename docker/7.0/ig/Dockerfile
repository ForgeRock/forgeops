FROM gcr.io/forgerock-io/ig/pit1:7.1.0-416d3022a8560b9a32583d50fe6d682209422171

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
