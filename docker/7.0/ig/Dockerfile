FROM gcr.io/forgerock-io/ig/pit1:7.1.0-6f80fcb8f3d5c911f5435bff68fa336b9435f4e6

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
