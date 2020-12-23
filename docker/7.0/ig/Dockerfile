FROM gcr.io/forgerock-io/ig/pit1:7.1.0-0b607db23e9ec9d72ad7406525269b796189c620

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
