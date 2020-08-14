FROM gcr.io/forgerock-io/ig/pit1:7.1.0-3c6b9422d982a73939d9e34ea38a0d9f499a0ea0

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
