FROM gcr.io/forgerock-io/ig:7.0.0-afe2e74fb5d3aaf5c9b11fc0996124a68fa6c058

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
