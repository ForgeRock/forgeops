FROM gcr.io/forgerock-io/ig/pit1:7.1.0-fcd17586502ee7dbf8c529a7484675e1317302ab

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
