FROM gcr.io/forgerock-io/ig/pit1:7.1.0-1df5769ab64dd196e05b2632f9f18f01c128c823

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
