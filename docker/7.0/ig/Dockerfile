FROM gcr.io/forgerock-io/ig-standalone:7.0.0-0884b9b719cfdfc478afcfa9d40cbf0d239335f0

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
