FROM gcr.io/forgerock-io/ig/pit1:7.1.0-5c4c68399f49cc88e0a5b03a4901be909a5f42a2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
