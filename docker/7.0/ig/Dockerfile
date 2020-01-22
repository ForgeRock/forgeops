FROM gcr.io/forgerock-io/ig/pit1:7.0.0-d4b88757a45204e435eb3d434ee9783c906a7af8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
