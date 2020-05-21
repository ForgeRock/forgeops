FROM gcr.io/forgerock-io/ig-standalone:7.0.0-67e813bc9430a2e2d9768649bdc60274924c16ef

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
