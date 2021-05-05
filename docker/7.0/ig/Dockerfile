FROM gcr.io/forgerock-io/ig/pit1:7.2.0-37144ac4840a2e44c3a2d0ec5e1d56a1476604b0

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
