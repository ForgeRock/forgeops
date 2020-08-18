FROM gcr.io/forgerock-io/ig/pit1:7.1.0-80dc595daee8a12573454e37ab91cf9903871087

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
