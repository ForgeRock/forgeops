FROM gcr.io/forgerock-io/ig/pit1:7.0.0-73408f2839fb0373db7018c5174af9bd0af92475

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
