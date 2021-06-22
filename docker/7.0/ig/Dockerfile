FROM gcr.io/forgerock-io/ig/pit1:7.2.0-03b2eca61ac88175b2540a03056aa6677fc9e750

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
