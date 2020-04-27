FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-e1a65b9e23867329fa5b88e95866504416fef42d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
