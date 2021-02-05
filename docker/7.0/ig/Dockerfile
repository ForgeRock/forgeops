FROM gcr.io/forgerock-io/ig/pit1:7.1.0-4cd91316898d892c8185b632e593cc71293990ca

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
