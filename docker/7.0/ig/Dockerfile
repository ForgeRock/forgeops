FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-a7a967ac615fa3d33391034d789e3ad2e1176cf3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
