FROM gcr.io/forgerock-io/ig/pit1:7.1.0-55bbd2d55d1276e221c49063608f8dc4ce2ee603

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
