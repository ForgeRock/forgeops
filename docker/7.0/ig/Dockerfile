FROM gcr.io/forgerock-io/ig/pit1:7.2.0-1dcc298419794f92548ce64f8d47bea09454fcb5

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
